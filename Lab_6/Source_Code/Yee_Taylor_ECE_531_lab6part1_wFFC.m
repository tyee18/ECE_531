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

%% Debugging flags
visualOffset          = false;
visualOffsetCorrected = false;
plot_2_1 = false;
plot_3_2 = false;
modType  = 'BPSK';

%% Impairments
snr = 15;
frequencyOffsetHz     = 1e5; % Offset in hertz
phaseOffset = 0; % Radians

%% Generate symbols
data = randi([0 samplesPerSymbol], numSamples, 1);

if strcmp(modType, 'DBPSK')
    mod = comm.DBPSKModulator(); % modulation scheme can be updated between sections 3.2.1 and 3.2.2 as needed
    coarseFreqComp = comm.CoarseFrequencyCompensator('Modulation','BPSK');
    fineFreqComp = comm.CarrierSynchronizer('Modulation','BPSK', ...
    'SamplesPerSymbol',samplesPerSymbol, 'CustomPhaseOffset',phaseOffset);
elseif strcmp(modType, 'QPSK')
    mod = comm.QPSKModulator(); % modulation scheme can be updated between sections 3.2.1 and 3.2.2 as needed
    coarseFreqComp = comm.CoarseFrequencyCompensator('Modulation','QPSK');
    fineFreqComp = comm.CarrierSynchronizer('Modulation','QPSK', ...
    'SamplesPerSymbol',samplesPerSymbol, 'CustomPhaseOffset',phaseOffset);
else
    mod = comm.BPSKModulator(); % let default be BPSK
    coarseFreqComp = comm.CoarseFrequencyCompensator('Modulation','BPSK');
    fineFreqComp = comm.CarrierSynchronizer('Modulation','BPSK', ...
    'SamplesPerSymbol',samplesPerSymbol, 'CustomPhaseOffset',phaseOffset);
end

modulatedData = mod.step(data);

%% Add TX Filter
TxFlt        = comm.RaisedCosineTransmitFilter('OutputSamplesPerSymbol', filterUpsample, 'FilterSpanInSymbols', filterSymbolSpan);
filteredData = step(TxFlt, modulatedData);

%% Add noise
noisyData = awgn(filteredData,snr);%,'measured');

%% Setup visualization object(s)
sa = dsp.SpectrumAnalyzer('SampleRate',sampleRateHz,'ShowLegend',true);

%% Add error vector magnitude (EVM)
evm = comm.EVM('ReferenceSignalSource','Estimated from reference constellation');

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

        % Correct data with fine frequency compensator
        [fineCorrectedData(timeIndex), correctedPhaseEstimate(timeIndex)] = ...
            fineFreqComp(coarseCorrectedData(timeIndex));

        if visualOffset
            % Visualize Error
            step(sa,[noisyData(timeIndex),offsetData(timeIndex)]);pause(0.1); %#ok<*UNRCH>
        end

        if visualOffsetCorrected
            % Visualize Corrected Data
            step(sa,[noisyData(timeIndex),coarseCorrectedData(timeIndex)]);pause(0.1); %#ok<*UNRCH>
        end

    end

    %% Section 2.1: Set up fig info to be saved
    if plot_2_1
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
    end


    %% Section 3: Set up fig info to be saved
    if plot_3_2
        figPlot = figure;
        figName = sprintf("MATLAB_3.2_offset_%d_mod_%s", offsetIncrease, modType);
        df = sampleRateHz/frameSize;
        %% Plot
        frequencies = -sampleRateHz/2:df:sampleRateHz/2-df;
        spec = @(sig) fftshift(10*log10(abs(fft(sig))));
        h = plot(frequencies, spec(noisyData(timeIndex)),...
            frequencies, spec(coarseCorrectedData(timeIndex)));
        grid on;xlabel('Frequency (Hz)');ylabel('PSD (dB)');
        legend('Original','Coarse Corrected Offset','Location','Best');
        title(sprintf('(%s) PSDs of coarse freq corrected offset and original tx signals with offset = %d Hz', modType, offsetIncrease));
        NumTicks = 5;L = h(1).Parent.XLim;
        set(h(1).Parent,'XTick',linspace(L(1),L(2),NumTicks))

        %% Save figure
        saveas(figPlot, strcat(figName, '.fig'));
        saveas(figPlot, strcat(figName, '.jpg'));
    end

    rmsEVM = evm(correctedPhaseEstimate)

end
