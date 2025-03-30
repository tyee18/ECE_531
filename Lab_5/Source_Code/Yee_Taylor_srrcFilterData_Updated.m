clear all; close all;

% User tunable (samplesPerSymbol>=decimation)
samplesPerSymbol = 4; decimation = 2;
% Create a QPSK modulator System object and modulate data
qpskMod = comm.QPSKModulator('BitInput',true);
% Create a QPSK demodulator System object and modulate data
qpskDeMod = comm.QPSKDemodulator('BitOutput',true);
% Set up filters
% Note - add 'RolloffFactor' to each filter as needed (for beta, in lab
% equations).
rollOffFactors_2_1 = [0, 0.1, 0.25, 0.5, 1];
steps = 20;

for testFactors = 1:length(rollOffFactors_2_1)
    rollOffFactor = rollOffFactors_2_1(testFactors);
    rctFilt = comm.RaisedCosineTransmitFilter( ...
        'OutputSamplesPerSymbol', samplesPerSymbol, ...
        'RolloffFactor', rollOffFactor);
    rcrFilt = comm.RaisedCosineReceiveFilter( ...
        'InputSamplesPerSymbol',  samplesPerSymbol, ...
        'RolloffFactor', rollOffFactor, ...
        'DecimationFactor',       decimation);
    % Set up delay object
    VFD = dsp.VariableFractionalDelay;
    % Delay data with slowly changing delay
    rxFilt = [];
    for index = 1:1e3
        % Generate, modulate, and tx filter data
        data = randi([0 1],100,1);
        modFiltData = rctFilt(qpskMod(data));
        % Delay signal
        tau_hat = index/30;
        delayedsig = VFD(modFiltData, tau_hat);
        rxSig = awgn(delayedsig,25); % Add noise
        rxFilt = [rxFilt;rcrFilt(rxSig)]; % Rx filter
    end
    scope = spectrumAnalyzer('FrequencySpan','full', ...
        'Title',sprintf('RX frequency response of SRRC filter with roll-off factor = %s', string(rollOffFactor)), ...
        'ViewType', 'spectrum');

    % Receive and view signal
    for k=1:steps
        %scope(rxFilt)
    end
end

close all;


rollOffFactors_2_2 = [0.1, 0.5, 0.9];
for testFactors = 1:length(rollOffFactors_2_2)
    rollOffFactor = rollOffFactors_2_2(testFactors);
    rctFilt = comm.RaisedCosineTransmitFilter( ...
        'OutputSamplesPerSymbol', samplesPerSymbol, ...
        'RolloffFactor', rollOffFactor);
    rcrFilt = comm.RaisedCosineReceiveFilter( ...
        'InputSamplesPerSymbol',  samplesPerSymbol, ...
        'RolloffFactor', rollOffFactor, ...
        'DecimationFactor',       decimation);
    % Set up delay object
    VFD = dsp.VariableFractionalDelay;
    % Delay data with slowly changing delay
    rxFilt = [];
    for index = 1:1e3
        % Generate, modulate, and tx filter data
        data = randi([0 1],100,1);
        modFiltData = rctFilt(qpskMod(data));
        % Delay signal
        tau_hat = index/30;
        delayedsig = VFD(modFiltData, tau_hat);
        % Add noise at the rx
        rxSig = awgn(delayedsig,25); % Add noise
        rxFilt = [rxFilt;rcrFilt(rxSig)]; % Rx filter
        demodNoiseData = qpskDeMod(rcrFilt(rxSig));
        demodFiltData  = qpskDeMod(rcrFilt(rxFilt));
        %newRxFilt = rcrFilt(rxSig);
    end

    % For Subplot 1:
    % Fill in the tx signal lost due to decimation,
    % compared to the Rx Data and Tx SRRC.
    newTxDataSub1 = [];
    ogTxDataInd   = 1;

    for subplot1_DataInd = 1:length(modFiltData)
        if mod(subplot1_DataInd, 2) == 0
            newTxDataSub1(subplot1_DataInd) = nan;
            ogTxDataInd = ogTxDataInd + 1;
        else
            newTxDataSub1(subplot1_DataInd) = data(ogTxDataInd);
        end
    end

    %{
    % For Subplot 2:
    % Fill in the tx and rx data lost due to decimation, compared to the Rx
    % filter output
    newFiltDataSub2 = [];
    ogRxFiltInd     = 1;

    for subplot2_FiltInd = 1:length(demodFiltData)
        if mod(subplot2_FiltInd, 2) == 0
            newFiltDataSub2(subplot2_FiltInd) = nan
            ogRxFiltInd = ogRxFiltInd + 1
        else
            newFiltDataSub2(subplot2_FiltInd) = newRxFilt(ogRxFiltInd)
        end
    end
    %}

    % For Subplot 2:
    % Fill in the tx and rx data lost due to decimation, compared to the Rx
    % filter output
    newTxDataSub2 = [];
    ogTxDataInd    = 1;
    rxFiltTxDataRatio = length(rxFilt) / length(data);

    for subplot2_txDataInd = 1:rxFiltTxDataRatio:length(rxFilt)
        newTxDataSub2(subplot2_txDataInd) = data(ogTxDataInd);
        newTxDataSub2(subplot2_txDataInd+1:1:ogTxDataInd*rxFiltTxDataRatio) = nan;
        ogTxDataInd = ogTxDataInd + 1;
    end
%{
    newDemodDataSub2 = [];
    ogDemodDataInd   = 1;
    rxFiltDemodRatio = length(rxFilt) / length(demodNoiseData);

    for subplot2_demodDataInd = 1:rxFiltDemodRatio:length(rxFilt)
        newDemodDataSub2(subplot2_demodDataInd) = demodNoiseData(ogDemodDataInd);
        newDemodDataSub2(subplot2_demodDataInd+1:1:ogDemodDataInd*rxFiltDemodRatio) = nan;
        ogDemodDataInd = ogDemodDataInd + 1;
    end
%}
    %% Subplot 1: Tx Data, Rx Data w/ Noise, Tx SRRC
    figure;
    subplot(3, 1, 1);
    hold on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    stem(newTxDataSub1, '-kx');
    plot(abs(rxSig), 'r');
    plot(abs(modFiltData), '-bo');
    hold off;
    legend('Transmitted Data', 'Received Data With Noise', 'Transmitted SRRC');
    title(sprintf('Pulse shaping vs non-pulse shaping with roll-off factor = %s', string(rollOffFactor)));

    %% Subplot 2: Tx Data, Rx Filtered Output, Demodulated
    subplot(3, 1, 2); 
    xlabel('Time (ms)');
    ylabel('Amplitude');
    hold on;
    stem(newTxDataSub2, '-kx');
    plot(abs(rxFilt), 'r');
    stem(demodFiltData, '-mo');
    %{
    stem(newTxDataSub1, '-kx');
    plot(abs(newFiltDataSub2), 'r');
    stem(demodFiltData, '-mo');
    %}
    legend('Transmitted Data', 'Rcv Filter Output', 'Demodulated');
    hold off;

    %% Subplot 3: Tx Data, Rx Data w/ Noise, Demodulated
    subplot(3, 1, 3);
    hold on;
    xlabel('Time (ms)');
    ylabel('Amplitude');
    hold on;
    stem(newTxDataSub1, '-kx');
    plot(abs(rxSig), 'r');
    stem(demodNoiseData, '-mo');
    hold off;
    legend('Transmitted Data', 'Received Data With Noise', 'Demodulated');

    
end