%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function Name: mainTestDriver
% Author:        Taylor Yee
% Description:   This function reads in the audio file provided,
%                and prints the calculated beats per minute (BPM) to the
%                command window, along with other helpful identifying info,
%                and plots the data with detected onsets, or "beats".
% Required Inputs:
%     - audioFile: The full path to the audio file to be read.
%     - songID:    How the song will be identified in plots.
% Optional Inputs:
%     - bpfFreq:       The bandpass filter frequency range. Default
%                      is 60 - 250 Hz.
%     - beatThreshold: The minimum wave amplitude threshold to be
%                      considered a "beat". Default is 0.30.
%     - fs:            Sampling frequency of clip. Default is 48000 Hz.
%     - secondsToRead: How many seconds of audio to read out for BPM calcs.
%                      Default is 30.0s.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mainTestDriver(audioFile, songID, varargin) % bpfFreq, beatThreshold, fs, secondsToRead)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Some quick notes on default values chosen below:
    %%
    %% - bpfFreq = 60-250Hz. This is the "bass" frequency zone of an audio
    %%   mix, and understandably, is where most of the rhythm and bass can
    %%   be found. The "sub-bass" (20-60Hz) zone is another good option.
    %%
    %% - beatThresold = 0.25. The amplitude of the waveform that constitutes
    %%   a "beat". There's not really any math behind this value - it was
    %%   chosen fairly arbitrarily after studying several waveforms using
    %%   the bass frequency zone. For the sub-bass, use 0.15.
    %%
    %% - fs = 48000 (Hz). One of the most common sampling rates for audio
    %%   recording and production.
    %%
    %% - secondsToRead = 30 (seconds). Enough time for a song to have at
    %%   least *some* form of rhythm in the mix.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Fill in default values depending on what options the user passes in.
    % Note that freqRange and beatThreshold MUST be provided together.
    if length(varargin) == 4
        bpfFreq       = varargin{1};
        beatThreshold = varargin{2};
        fs            = varargin{3};
        secondsToRead = varargin{4};
    
    % Note that sampFreq and sampTime MUST be provided together.
    elseif length(varargin) == 2
        bpfFreq       = varargin{1};
        beatThreshold = varargin{2};
        fs            = 48000;
        secondsToRead = 30;

    % If no additional arguments are provided, set all to default values.
    else
        bpfFreq       = [60 250];
        beatThreshold = 0.25;
        fs            = 48000;
        secondsToRead = 30;
    end
    
    % Set up some constants and variables to be used downstream.
    minToSec = 1/60;
    % This can be changed, but most mainstream songs tend to sit in the
    % 80-130 BPM range.
    minBPM = 60;
    minBPS = minBPM * minToSec;
    maxOnsetSampleDelta = fs / minBPS;

    maxBPM = 180;
    maxBPS = maxBPM * minToSec;
    minOnsetSampleDelta = fs / maxBPS;

    %% Import the audio data and run it through a bandpass filter to hone
    %% in on the frequencies that will provide the most likely rhythmic
    %% aspects.
    data         = importAudio(audioFile, fs, secondsToRead);
    filteredData = bandpass(data, bpfFreq, fs);

    [onsetsDetected, beatsPerMinute] = determineBPM(filteredData, fs, beatThreshold, minOnsetSampleDelta, maxOnsetSampleDelta);
    fprintf('*-----------------------------------------------------------*\n');
    fprintf('SongID: %s\n', songID);
    fprintf('Freq Range: %d - %d Hz\n', bpfFreq(1), bpfFreq(end));
    fprintf('Beat Threshold: %d\n', beatThreshold);
    fprintf('Sample Rate: %d\n', fs);
    fprintf('Seconds of Data Analyzed: %d\n', secondsToRead);
    fprintf('Calculated BPM: %d beats per minute\n', floor(beatsPerMinute));
    fprintf('*-----------------------------------------------------------*\n');

    showOnsetData(filteredData, onsetsDetected, songID);
    %{
    % Plotting available to show bandpass filter original vs filtered
    % signal
    bandpass(data, bpfFreq, fs);
    %}
end