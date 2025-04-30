%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function Name: importAudio
% Description: This function imports audio data provided from GNU Radio
%              flowgraph fileSink.
% Inputs:
%     - file:          Full path to the audio data.
%     - sampFreq:      The sampling frequency of the data.
%     - secondsToRead: How many seconds of data to be read out.
% Outputs:
%     - audioStream: The audio data as a raw stream of complex32
%                    datapoints.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [audioStream] = importAudio(file, sampFreq, secondsToRead)
    samplesToRead = floor(secondsToRead * sampFreq);
    [fid, msg]    = fopen(file, 'r');
    audioStream   = fread(fid, [2 samplesToRead], "*float32");
    fclose(fid);    
    audioStream   = complex(audioStream(1, :), audioStream(2, :)); % converts stereo (dual channel) audio to mono (single channel)
end