clear all; close all;

%% General system details
sampleRateHz = 1e6; % Sample rate
sampleRateOffsetStepHz = 0.1*sampleRateHz; % Offset in hertz
samplesPerSymbol = 1;
frameSize = 2^10;
numFrames = 100;
numSamples = numFrames*frameSize; % Samples to simulate
modulationOrder  = 2;
filterUpsample   = 4;
filterSymbolSpan = 8;

%% Impairments
snr = 15;
frequencyOffsetHz     = 1e5; % Offset in hertz
phaseOffset = 0; % Radians

%% Generate symbols
data = randi([0 samplesPerSymbol], numSamples, 1);
mod = comm.QPSKModulator(); % modulation scheme can be updated between sections 3.2.1 and 3.2.2 as needed
modulatedData = mod.step(data);

%% Add TX Filter
TxFlt        = comm.RaisedCosineTransmitFilter('OutputSamplesPerSymbol', filterUpsample, 'FilterSpanInSymbols', filterSymbolSpan);
filteredData = step(TxFlt, modulatedData);

%% Add noise
noisyData = awgn(filteredData,snr);%,'measured');

%% Setup visualization object(s)
sa = dsp.SpectrumAnalyzer('SampleRate',sampleRateHz,'ShowLegend',true);

%% Set up coarse frequency compensator (FFT-based by default)
coarseFreqComp = comm.CoarseFrequencyCompensator('Modulation','QPSK'); % modulation scheme can be updated between sections 3.2.1 and 3.2.2 as needed
ModulationType = string(coarseFreqComp.Modulation);

%% Model of error
% Add frequency offset to baseband signal

for offsetIncrease = sampleRateOffsetStepHz:sampleRateOffsetStepHz:sampleRateHz
    % Precalculate constant(s)
    normalizedOffset = 1i.*2*pi*(offsetIncrease)./sampleRateHz;

    offsetData    = zeros(size(noisyData));
    coarseCorrectedData = zeros(size(noisyData));
    for k=1:frameSize:numSamples*filterUpsample

        % Create phase accurate vector
        timeIndex = (k:k+frameSize-1).';
        freqShift = exp(normalizedOffset*timeIndex + phaseOffset);

        % Offset data and maintain phase between frames
        offsetData(timeIndex) = (noisyData(timeIndex).*freqShift);

        % Correct data with coarse frequency compensator
        coarseCorrectedData(timeIndex) = coarseFreqComp(offsetData(timeIndex));

        % Visualize Error - todo, this can be commented out for expediency
        %step(sa,[noisyData(timeIndex),offsetData(timeIndex)]);pause(0.1); %#ok<*UNRCH>

        % Visualize Corrected Data - todo, this can be commented out for expediency
        %step(sa,[noisyData(timeIndex),coarseCorrectedData(timeIndex)]);pause(0.1); %#ok<*UNRCH>

    end
    %% Section 2.1: Set up fig info to be saved
    figPlot = figure;
    figName = sprintf("MATLAB_2.1_2_offset_%d", offsetIncrease);
    df = sampleRateHz/frameSize;
    %% Plot
    frequencies = -sampleRateHz/2:df:sampleRateHz/2-df;
    spec = @(sig) fftshift(10*log10(abs(fft(sig))));
    h = plot(frequencies, spec(noisyData(timeIndex)),...
        frequencies, spec(offsetData(timeIndex)));
    grid on;xlabel('Frequency (Hz)');ylabel('PSD (dB)');
    legend('Original','Offset','Location','Best');
    title(sprintf('PSDs of offset and original transmitted signals with offset = %d Hz', offsetIncrease));
    NumTicks = 5;L = h(1).Parent.XLim;
    set(h(1).Parent,'XTick',linspace(L(1),L(2),NumTicks))

    %% Save figure
    saveas(figPlot, strcat(figName, '.fig'));
    saveas(figPlot, strcat(figName, '.jpg'));


    %% Section 3: Set up fig info to be saved
    figPlot = figure;
    figName = sprintf("MATLAB_3.2_2_offset_%d", offsetIncrease);
    df = sampleRateHz/frameSize;
    %% Plot
    frequencies = -sampleRateHz/2:df:sampleRateHz/2-df;
    spec = @(sig) fftshift(10*log10(abs(fft(sig))));
    h = plot(frequencies, spec(noisyData(timeIndex)),...
        frequencies, spec(coarseCorrectedData(timeIndex)));
    grid on;xlabel('Frequency (Hz)');ylabel('PSD (dB)');
    legend('Original','Coarse Corrected Offset','Location','Best');
    title(sprintf('(%s) PSDs of coarse freq corrected offset and original tx signals with offset = %d Hz', ModulationType, offsetIncrease));
    NumTicks = 5;L = h(1).Parent.XLim;
    set(h(1).Parent,'XTick',linspace(L(1),L(2),NumTicks))

    %% Save figure
    saveas(figPlot, strcat(figName, '.fig'));
    saveas(figPlot, strcat(figName, '.jpg'));
end
