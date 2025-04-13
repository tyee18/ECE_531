clear all; close all;

%% Debugging flags
visuals = false;
displayPayload = true;

%% General system details
sampleRateHz = 1e6; % Sample rate
samplesPerSymbol = 8;
numFrames = 1e2;
modulationOrder = 2;
filterSymbolSpan = 4;
barkerLength = 26; % Must be even

%% Impairments
snr = 15;

%% Generate symbols
bits = double(ASCII2bits('Arizona')); % Generate message (use booktxt.m for a long message)
% Preamble
hBCode = comm.BarkerCode('Length',7,'SamplesPerFrame', barkerLength/2);
barker = step(hBCode)>0;
frame = [barker;barker;bits];
preamble = [barker;barker];
frameSize = length(frame);
modD = comm.DBPSKModulator();
bMod = clone(modD);
modulatedData = modD.step(frame);

%% Add TX/RX Filters
TxFlt = comm.RaisedCosineTransmitFilter(...
    'OutputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan);

RxFlt = comm.RaisedCosineReceiveFilter(...
    'InputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan,...
    'DecimationFactor', samplesPerSymbol);% Set to filterUpsample/2 when introducing timing estimation
RxFltRef = clone(RxFlt);

%% Add noise source
chan = comm.AWGNChannel( ...
    'NoiseMethod',  'Signal to noise ratio (SNR)', ...
    'SNR',          snr, ...
    'SignalPower',  1, ...
    'RandomStream', 'mt19937ar with seed');

%% Setup visualization object(s)
hts1 = dsp.TimeScope('SampleRate', sampleRateHz,'TimeSpan', frameSize*2/sampleRateHz);
hAP = dsp.ArrayPlot;
hAP.YLimits = [-3 35];

%% Demodulator
demod = comm.DBPSKDemodulator;

%% Model of error
BER = zeros(numFrames,1);
PER = zeros(numFrames,1);
for k=1:numFrames
    
    % Insert random delay and append zeros
    delay = randi([0 frameSize-1-TxFlt.FilterSpanInSymbols]);% Delay should be at worst 1 frameSize-"filter delay"
    delayedSignal = [zeros(delay,1); modulatedData;...
        zeros(frameSize-delay,1)];
    
    % Filter signal
    filteredTXDataDelayed = step(TxFlt, delayedSignal);
    
    % Pass through channel
    noisyData = step(chan, filteredTXDataDelayed);
    
    % Filter signal
    filteredData = step(RxFlt, noisyData);
    plot(real(filteredData)); % todo: delete
    
    % Visualize Correlation
    if visuals
        step(hts1, filteredData);pause(0.1);
    end
    
    
    % Remove offset and filter delay
    frameStart = delay + RxFlt.FilterSpanInSymbols + 1;
    frameHatNoPreamble = filteredData(frameStart:frameStart+frameSize-1);
    %{
    % Demodulate and check
    dataHat = demod.step(frameHatNoPreamble);
    demod.release(); % Reset reference
    BER(k) = mean(dataHat-frame);
    PER(k) = BER(k)>0;
    
    if displayPayload
        payloadStart = barkerLength+1; % Trim preamble to display ASCII payload
        rxTxt = bits2ASCII(dataHat(payloadStart:end), 1);
    end
    %}
    
    % New code: matched filter
    mf = bMod(preamble);

    % Remove offset and filter delay - do this now based on filter function
    corr = filter(mf(end:-1:1), 1, filteredData(length(mf):end), filteredData(1:length(mf)-1));
    % Determine max value
    [m, mf_delay] = max(corr);
    %plot(real(corr));

    % Not sure why we needed to get rid of the "RxFlt.FilterSpanInSymbols +
    % 1" from the above implementation - maybe because this was already
    % accounted for in using the filter function + accounting for the
    % preamble in the mf?
    frameStartWPreamble = mf_delay;
    frameHatWPreamble = filteredData(frameStartWPreamble:frameStartWPreamble+frameSize-1);
    
    % Demodulate and check
    dataHatWPreamble = demod.step(frameHatWPreamble);
    demod.release(); % Reset reference
    BER(k) = mean(dataHatWPreamble-frame);
    PER(k) = BER(k)>0;
    
    dataMF = demod.step(frameHatWPreamble);

    if displayPayload
        payloadStart = barkerLength+1; % Trim preamble to display ASCII payload
        rxTxt = bits2ASCII(dataHatWPreamble(payloadStart:end), 1);
    end
end

% Result
fprintf('PER %2.2f\n',mean(PER));











