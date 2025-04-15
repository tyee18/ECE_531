clear all; close all;

% Setup debugging flags
plotTiming   = true;
xcorrVisuals = false;

% There are two primary ways to estimate the start of a frame in MATLAB:
% the xcorr and filter functions.
% Method 1: xcorr
%corr = xcorr(y,seq);

% Method 2: filter
% This implementation does NOT give a peak, because the filter function does
% not include a time reversal
%corr = filter(seq, 1, y);
% To implement time reversal:
%corr = filter(seq(end:-1:1), 1, y);
% To pre-load to get rid of delay from preamble sequence:
%corr = filter(seq(end:-1:1), 1, y(length(seq):end), y(1:length(seq)-1));
sequenceLength = [10 100 1000 10000 100000];

timingDataXCorr  = [];
timingDataFilter = [];

for lengthInd = 1:length(sequenceLength)

    % Setup data to be used
    currentSeqLength = sequenceLength(lengthInd);
    [y, seq] = BarkerAutoCorr(currentSeqLength);
    
    % Start timing for xcorr method
    tic;
    xcorr(y,seq);
    timingDataXCorr(lengthInd) = toc;

    % Repeat the same timing benchmark using the filter method
    tic;
    filter(seq(end:-1:1), 1, y(length(seq):end), y(1:length(seq)-1));
    timingDataFilter(lengthInd) = toc;
end

if plotTiming

    % Setup basic labels and data needed
    xlabels        = ["XCorr Method", "Filter Method"];
    compTimingData = [timingDataXCorr; timingDataFilter];

    % Plot data
    figure;
    title('Sequence Length vs Execution Time of MATLAB Estimation Methods');
    hold on;
    dataBars = bar(xlabels, compTimingData);
    ylabel("Execution time (s)");

    % Create a legend for the different bars - this will be dependent on
    % the values set in 'sequenceLength', above.
    set(dataBars, {'DisplayName'}, {'10','100','1000', '10000', '100000'}')
    leg = legend();
    title(leg, 'Sequence Length');
    for dataLabelInd = 1:length(sequenceLength)
        dataBars(dataLabelInd).Labels = dataBars(dataLabelInd).YData;
    end
    hold off;

    % Next, plot benchmark timing as ratio:
    figure;
    title('Timing Performance Ratio of XCorr Method / Filter Method');
    hold on;
    dataBars = bar(string(sequenceLength), timingDataXCorr ./ timingDataFilter);
    xlabel('Sequence Length');
    ylabel('Ratio');
    hold off;
end

% Moved class sample code into a different block that may or may not be
% executed depending on the study.
if xcorrVisuals
    % Show Barker Autocorrelations search example
    sequenceLength = 13;
    hBCode = comm.BarkerCode('Length',7,'SamplesPerFrame', sequenceLength);
    seq = step(hBCode);
    gapLen = 100;
    gapLenEnd = 200;
    gen = @(Len) 2*randi([0 1],Len,1)-1;
    y = [gen(gapLen); seq; gen(gapLenEnd)];
    corr = xcorr(y,seq);

    L = length(corr);
    [v,i] = max(corr);

    %% Plot
    figure;
    subplot(2,1,1);
    h1 = plot(y);grid on;title('Sequence');xlabel('Samples');
    hold on;
    h2 = stem(gapLen+1,2);
    hold off;
    ylim([-3 3]);

    subplot(2,1,2);title('Cross-Correlation');xlabel('Samples');
    hold on;
    h3 = plot(corr);grid on;
    h6 = stem(i,v);
    hold off;

    % Estimation of peak position
    % The correlation sequence should be 2*L-1, where L is the length of the
    % longest of the two sequences
    %
    % The first N-M will be zeros, where N is the length of the long sequence
    % and N is the length of the shorter sequence
    %
    % The peak itself will occur at zero lag, or when they are directly
    % overlapping, resulting in a peak in the middle sample in correlation

    numZeros = length(y) - sequenceLength;
    fromSeqEdge = gapLen + sequenceLength;
    peakPosEst = numZeros + fromSeqEdge;
    hold on;
    h4 = stem(peakPosEst,-v);
    legend([h6,h4],'True Peak Position','Estimated Peak Position','Location','Best');
    hold off;

    % Estimate 'gapLen' with known BarkerLength and Number of starting zeros
    [~,p] = max(corr);
    numZeros = length(y) - sequenceLength;
    estGapLen = p - numZeros - sequenceLength + 1;
    subplot(2,1,1);
    hold on;
    h5 = stem(estGapLen,-2);
    legend([h2 h5],'True Start','Estimated Start','Location','Best');
    hold off;

    % Draw offset
    p1 = [0 v+3];
    p2 = [numZeros v+3];
    dp = p2-p1;
    subplot(2,1,2);
    hold on;
    % Zeros Lag
    h=quiver(p1(1),p1(2),dp(1),dp(2),0, 'Color','k');
    text(dp(1)/4,25, 'Zeros Lag','FontSize',11)
    hold off;
end

% Moves common code into function that can be called in the context of the
% loop above for different sequence lengths.
function [y, seq] = BarkerAutoCorr(sequenceLength)
    % Show Barker Autocorrelations search example
    hBCode = comm.BarkerCode('Length',7,'SamplesPerFrame', sequenceLength);
    seq = step(hBCode);
    gapLen = 100;
    gapLenEnd = 200;
    gen = @(Len) 2*randi([0 1],Len,1)-1;
    y = [gen(gapLen); seq; gen(gapLenEnd)];
end