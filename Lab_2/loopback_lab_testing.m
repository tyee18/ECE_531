clear all; close all;

T = 1/300;

% Setup Receiver
rx=sdrrx('Pluto','OutputDataType','double','SamplesPerFrame',2^15, 'GainSource','Manual', 'Gain',50);
% Setup Transmitter
tx = sdrtx('Pluto','Gain',-30);


% Transmit sinewave
sine = dsp.SineWave('Amplitude',50,...
                    'Frequency',300,...
                    'SampleRate',rx.BasebandSampleRate,...
                    'SamplesPerFrame', 2^12,...
                    'ComplexOutput', true);
tx.transmitRepeat(sine()); % Transmit continuously
rx_full = rx();
pRMS_rx_full = rms(rx_full).^2;
% Setup Scope
samplesPerStep = rx.SamplesPerFrame/rx.BasebandSampleRate;
steps = 3;
ts = dsp.TimeScope('SampleRate', rx.BasebandSampleRate,...
                   'TimeSpan', samplesPerStep*steps,...
                   'BufferLength', rx.SamplesPerFrame*steps);
%{
% Receive and view sine
for k=1:steps
  ts(rx());
end
%}

sine_50_pct_duty = sine();
sine_50_pct_duty(1:length(sine_50_pct_duty)/2, 1) = 0;
tx.transmitRepeat(sine_50_pct_duty); % Transmit continuously
rx_50_pct = rx();

pwr_noise = rms(rx_50_pct(1:length(rx_50_pct)/2) + ...
    rx_full(1:length(rx_full)/2)).^2
pwr_sigpnoise = rms(rx_50_pct((length(rx_50_pct)/2) + 1:end) + ...
    rx_full((length(rx_full)/2) + 1:end)).^2

snr = 10*log((pwr_sigpnoise - pwr_noise) / pwr_noise)

tx.release();