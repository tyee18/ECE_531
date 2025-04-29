%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: Taylor Yee
% Course: ECE 531
% Assignment: ECE 531 Term Project
% Description: TBD: FILL ME
% Function name list:
%     - testDriver
%     - extractAudio
%     - resampleAudio
%     - normalizeAudio
%     - determineChangePoints
%     - determineOnsets
%     - findNoteFreqs
%     - convertFreqsToNotes
% Each function comes with its own header, as well as a list of required
% inputs, optional inputs, and outputs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

% Set up basic parameters
debugFlag = true;
secToMin = 60; % converting from seconds to minutes
minToSec = 1/60; % converting from minutes to seconds
Fs = 48000; % sampling rate of audio to file sink - different than sampling rate of audio live output stream
% calculated by taking (sample rate at LPF / decimation at LPF) /
% decimation at demodulator.
freqRange = [60 150]; % range of frequencies to look for changes in to calculate BPM
%freqRange = [20 60];
% 60 - 250 Hz is generally where the "bass" range lives, and provides the
% most consistent rhythm.

beatThreshold = 0.15; % use this for freqRange [20 60] aka sub-bass
%beatThreshold = 0.3; % use this for freqRange [60 150] aka bass

maxBPM = 160;
maxBPS = maxBPM * minToSec;

% Initialize variables
numOnsetsDetectedInSamples = 0;
numOnsetsDetectedInBPM = 0;
secondsToRead = 30; % can be changed based on user-specified time
samplesToRead = floor(secondsToRead * Fs);

songID = 'smooth-santana';
[fid, msg] = fopen("Pluto_Audio_Samples\30s_clips_complex32\smooth_santana", 'r');
data = fread(fid, [2 samplesToRead], "*float32");
fclose(fid);

audioClipTime = length(data)/Fs; % needed for bpm calculation downstream

data = complex(data(1, :), data(2, :)); % converts stereo (dual channel) audio to mono (single channel)
maxBPMAdjusted = maxBPM * (audioClipTime * minToSec); % this can be changed, but most mainstream songs tend to sit in the 80-130 BPM range. Use 200 as a bit of overkill, can be refined.
maxOnsetsAllowedinSamples = (Fs / maxBPMAdjusted) * secToMin; % expresses max BPM in terms of samples instead of time
% TODO: maxOnsets to be used later on, if the calculations somehow have
% more onsets than allowable for songs

minSampleDelta = Fs / maxBPS;

% Apply bandpass filter to isolate specified frequency range
filteredData = bandpass(data, freqRange, Fs);

% Find first onset index
% For consistency, assume that the "onset" starts at the positive
% wavelength energy peak, not the negative
firstOnset = find(real(filteredData) > beatThreshold, 1);
possibleBeatOnsets = find(real(filteredData) > beatThreshold);
tempFinalOnsets = [firstOnset];
tempIndex = 2;

for index = 2:length(possibleBeatOnsets)
    currentIndex = tempFinalOnsets(tempIndex - 1);
    % Next index has to be AT LEAST minBPSToSamples ahead of the current
    % index
    testBeatInd = possibleBeatOnsets(index);
    if testBeatInd > currentIndex + minSampleDelta
        tempFinalOnsets = [tempFinalOnsets testBeatInd];
        tempIndex = tempIndex + 1;
    end
end
avgBeatsPerSample = mean(diff(tempFinalOnsets));
finalBeatsPerMin  = (Fs / avgBeatsPerSample) * secToMin

if debugFlag
    % Plots the filtered signal in terms of number of samples. Note that
    % this only plots the real component (which is fine because for our
    % audio case, real and imaginary components will always be identical)
    figure;
    plot([1:samplesToRead], filteredData);
    hold on;
    %xline(firstOnset-(minBPSToSamples/2):minBPSToSamples:samplesToRead, '--r');
    xline(tempFinalOnsets, '--r');
    title(['Filtered Signal of ' songID]); xlabel('Number of samples');

    % Plots the original and filtered signals in terms of time and
    % frequency response
    %figure;
    %bandpass(data, freqRange, Fs);
end


%% Additional code here for experiments with frequency domain analysis
%{
% frequency domain aspect may not be needed
fftFilteredData = fft(filteredData);

% Transform data to frequency domain, filter out unwanted frequencies and
% perform spectral analysis (aka onset detection), then transform back
% to time domain.
% In the frequency domain, filter and determine onsets
fftData = fft(data);
fftNewFilteredData = bandpass(fftData, freqRange, Fs);

stftData = stft(data, Fs, 'Window', hamming(1024), 'OverlapLength', 1024 - 512, 'FFTLength', 1024);

% Transform back to time domain - is this fully necessary?
timeNewFilteredData = ifft(fftNewFilteredData);
%}