clear all; close all;

%% Debugging flags
visuals = false;
displayPayload = false;

%% General system details
sampleRateHz = 1e6; % Sample rate
samplesPerSymbol = 8;
numFrames = 1e2;
modulationOrder = 2;
filterSymbolSpan = 4;
barkerLength = 26; % Must be even

%% Impairments
snr = 0:20;

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

%% Setup visualization object(s)
hts1 = dsp.TimeScope('SampleRate', sampleRateHz,'TimeSpan', frameSize*2/sampleRateHz);
hAP = dsp.ArrayPlot;
hAP.YLimits = [-3 35];

%% Demodulator
demod = comm.DBPSKDemodulator;
PERdata = [];

%% Model of error
for snrInd = 1:length(snr)
    currentSNR = snr(snrInd);
    BER = zeros(numFrames,1);
    PER = zeros(numFrames,1);

    %% Add noise source
    chan = comm.AWGNChannel( ...
        'NoiseMethod',  'Signal to noise ratio (SNR)', ...
        'SNR',          currentSNR, ...
        'SignalPower',  1, ...
        'RandomStream', 'mt19937ar with seed');
    for k=1:numFrames

        % Insert random delay and append zeros
        delay = randi([0 frameSize-1-TxFlt.FilterSpanInSymbols]);% Delay should be at worst 1 frameSize-"filter delay"
        delayedSignal = [zeros(delay,1); modulatedData;...
            zeros(frameSize-delay,1)];
        %plot(real(delayedSignal), '-or');

        % Filter signal
        filteredTXDataDelayed = step(TxFlt, delayedSignal);

        % Pass through channel
        noisyData = step(chan, filteredTXDataDelayed);

        % Filter signal
        filteredData = step(RxFlt, noisyData);
        % hold on; plot(real(filteredData), '-og');legend('delayedSignal',...
        % 'filteredData');hold off;

        % Visualize Correlation
        if visuals
            step(hts1, filteredData);pause(0.1);
        end


        %{
        % Remove offset and filter delay
        frameStart = delay + RxFlt.FilterSpanInSymbols + 1;
        frameHat   = filteredData(frameStart:frameStart+frameSize-1);

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

        % Matched filter on RX
        mf = bMod(preamble);

        % Remove offset and filter delay - do this now based on filter function
        % instead of using known delay

        % NOTE: There appears to be a mismatch here. Sometimes this is
        % correct, but sometimes this max provides a wildly incorrect (aka
        % mismatched) delay value. Troubleshooting...this appears to be
        % related to SNR values. Testing with this was done with a set
        % SNR = 15, and appears to be optimized for SNR values of AT LEAST
        % 6. Anything less than that, and the delay will always be somehow
        % VASTLY off, such that the code will crash, hence the need for the
        % try-catch block below.
        corr = filter(mf(end:-1:1), 1, filteredData(length(mf):end), filteredData(1:length(mf)-1));
        % Determine max value
        [m, mf_delay] = max(corr);
        %plot(real(corr));

        % Not sure why we needed to get rid of the "RxFlt.FilterSpanInSymbols +
        % 1" from the above implementation - maybe because this was already
        % accounted for in using the filter function + accounting for the
        % preamble in the matched filter?
        frameStartNoPreamble = mf_delay;
        try
            frameHatNoPreamble = filteredData(frameStartNoPreamble:frameStartNoPreamble+frameSize-1);
        catch me
            fprintf('%s\b', me.message);
        end

        % Demodulate and check
        dataHatNoPreamble = demod.step(frameHatNoPreamble);
        demod.release(); % Reset reference
        BER(k) = mean(dataHatNoPreamble-frame);
        PER(k) = BER(k)>0;

        dataMF = demod.step(frameHatNoPreamble);

        if displayPayload
            payloadStart = barkerLength+1; % Trim preamble to display ASCII payload
            rxTxt = bits2ASCII(dataHatNoPreamble(payloadStart:end), 1);
        end
    end

    PERdata(snrInd) = mean(PER);

    % Result
    fprintf('SNR: %d\n',currentSNR);
    fprintf('PER: %2.2f\n',mean(PER));
end

figure;
title('SNR vs PER of Matched Filter for Frame Synchronization');
hold on;
bar(string(snr), PERdata);
xlabel('SNR Value (dB)');
ylabel('Packet Error Rate (PER)');
hold off;











