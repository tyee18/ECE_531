clear all; close all;

% User tunable (samplesPerSymbol>=decimation)
samplesPerSymbol = 4; decimation = 2;
% Create a QPSK modulator System object and modulate data
qpskMod = comm.QPSKModulator('BitInput',true);
% Set up filters
% Note - add 'RolloffFactor' to each filter as needed (for beta, in lab
% equations).
rollOffFactor = 0;
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


% Setup Scope
%samplesPerStep = rx.SamplesPerFrame/rx.BasebandSampleRate;
steps = 20;
scope = spectrumAnalyzer('FrequencySpan','full', ...
                        'Title',sprintf('RX frequency response of SRRC filter with roll-off factor = %s', string(rollOffFactor)), ...
                        'ViewType', 'spectrum');

% Receive and view signal
for k=1:steps
    scope(rxFilt)
    %scope(rxFilt);
end