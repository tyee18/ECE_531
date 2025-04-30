%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function Name: determineBPM
% Description: This function estimates the beats-per-minute (BPM) of the
%              data provided.
% Inputs:
%     - filteredData:        Audio data post-BPF.
%     - sampFreq:            The sampling frequency of the data.
%     - waveThreshold:       The minimum amplitude threshold required to be
%                            counted as a "beat".
%     - minOnsetSampleDelta: The minimum distance between "beats".
% Outputs:
%     - onsetsDetected: Sample indices where "beats" were detected.
%     - beatsPerMin:    The calculated beats per minute of the audio.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [onsetsDetected, beatsPerMin] = determineBPM(filteredData, sampFreq, waveThreshold, minOnsetSampleDelta)
    % Conversion factor needed for BPM
    secToMin = 60;

    %% Find possible onset index. For consistency, assume that the "onset"
    %% starts at the positive wavelength energy peak, not the negative    
    possibleOnsets = find(real(filteredData) > waveThreshold);

    %% Set up final array of valid onset indices. Use the first located
    %% onset from above as a starting point.
    onsetsDetected = [possibleOnsets(1)];

    % Set up index for updating the final list
    tempIndex = 2;

    for possibleOnsetInd = 2:length(possibleOnsets)
        currentIndex = onsetsDetected(tempIndex - 1);
        %% The next onset index has to be AT LEAST minOnsetSampleDelta
        %% ahead of the current index. This ensures that the resulting BPM 
        %% cannot  exceed our (user-determined) desired calculation threshold.
        testInd = possibleOnsets(possibleOnsetInd);
        if testInd > currentIndex + minOnsetSampleDelta
            onsetsDetected = [onsetsDetected testInd];
            tempIndex = tempIndex + 1;
        end
    end

    avgBeatsPerSample = mean(diff(onsetsDetected));
    beatsPerMin       = (sampFreq / avgBeatsPerSample) * secToMin;
end