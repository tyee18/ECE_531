%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function Name: showOnsetData
% Description: This function plots the data with detected onsets as dashed
%              horizontal lines.
% Inputs:
%     - filteredData:   Audio data post-BPF.
%     - onsetsDetected: Sample indices where "beats" were detected.
%     - songID:         The song ID to be added to plot title.
% Outputs: None
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = showOnsetData(filteredData, onsetsDetected, songID)
    %% Plot the filtered signal in terms of number of samples. Note that
    %% this only plots the real component (which is fine because for our
    %% audio case, real and imaginary components will always be identical)
    figure;
    plot([1:length(filteredData)], filteredData);
    hold on; xline(onsetsDetected, '--m');
    title(strcat("Filtered Signal of ", songID, " with Onsets Detected")); xlabel('Number of samples');
end