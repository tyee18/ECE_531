%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function Name: showOnsetData
% Author:        Taylor Yee
% Description:   This function plots the data with detected onsets as
%                dashed horizontal lines.
% Inputs:
%     - filteredData:   Audio data post-BPF.
%     - sampFreq:       The sampling frequency of the data.
%     - onsetsDetected: Sample indices where "beats" were detected.
%     - songID:         The song ID to be added to plot title.
% Outputs: None
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = showOnsetData(filteredData, sampFreq, onsetsDetected, songID)
    %% Plot the filtered signal in terms of number of samples. Note that
    %% this only plots the real component (which is fine because for our
    %% audio case, real and imaginary components will always be identical)
    figPlot = figure;
    figName = strcat("Filtered Signal of ", songID, " with Onsets Detected");

    %% Convert inputs to time domain for plotting
    xData = [(1:length(filteredData))/sampFreq];
    xLines = onsetsDetected / sampFreq;

    %% Plot Data
    plot(xData, filteredData);
    hold on; xline(xLines, '--m');
    title(figName); xlabel('Time (s)'); ylabel('Amplitude');

    %% Save figure
    saveas(figPlot, strcat(figName, '.fig'));
    saveas(figPlot, strcat(figName, '.jpg'));
end