clear all; close all;

%% General system details
sampleRateHz = 1e6; samplesPerSymbol = 8;
frameSize = 2^10; numFrames = 200;
numSamples = numFrames*frameSize; % Samples to simulate
modulationOrder = 2; filterSymbolSpan = 4;
%% Visuals
cdPre = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'Name','Baseband');
cdPost = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'Name','Baseband with Timing Offset');
cdPostCorrect = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'Name','Baseband with Timing Offset and SymbolSync Correction');
cdPre.Position(1) = 50;
cdPost.Position(1) = cdPre.Position(1)+cdPre.Position(3)+10;% Place side by side
cdPostCorrect.Position(1) = cdPre.Position(1)+cdPre.Position(3)+20;% Place side by side
%% Impairments
snr = [0:5:20];
phaseOffset  = [0, pi/8]; % radians
timingOffset = samplesPerSymbol*0.01; % Samples

%% Generate symbols
data = randi([0 modulationOrder-1], numSamples*2, 1);
modulatorObject = comm.DBPSKModulator(); modulatedData = modulatorObject(data);
%% Add TX/RX Filters
TxFlt = comm.RaisedCosineTransmitFilter(...
    'OutputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan);
RxFlt = comm.RaisedCosineReceiveFilter(...
    'InputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan,...
    'DecimationFactor', samplesPerSymbol/2);
RxFltRef = clone(RxFlt);
%% Add delay
varDelay = dsp.VariableFractionalDelay;

%% Add error vector magnitude (EVM)
evm = comm.EVM('ReferenceSignalSource','Estimated from reference constellation');

%% Add timing correction
symbolSync = comm.SymbolSynchronizer('TimingErrorDetector', 'Zero-Crossing (decision-directed)');

%% Model of error
% Add timing offset to baseband signal
filteredData       = [];
TimingCorrectedEVM = [];

%% Loop to view all combinations for lab
for phaseOffsetValInd = 1:length(phaseOffset)
    %% Phase offset can either be default (0) or pi/8, per lab reqs
    currentPhaseOffset = phaseOffset(phaseOffsetValInd);

    %% Set up phase offset object
    pfo = comm.PhaseFrequencyOffset('PhaseOffset', rad2deg(currentPhaseOffset), 'SampleRate', sampleRateHz);

    %% Loop through different SNR values
    for snrValInd = 1:length(snr)

        %% Update current SNR value under test
        currentSNR = snr(snrValInd);

        %% Add noise source - this has been moved to update dynamically
        chan = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',currentSNR, ...
            'SignalPower',1,'RandomStream', 'mt19937ar with seed');

        %% Now perform signal processing
        for k=1:frameSize:(numSamples - frameSize)
            timeIndex = (k:k+frameSize-1).';
            % Filter signal
            filteredTXData = TxFlt(modulatedData(timeIndex));
            % Pass through channel
            noisyData = chan(filteredTXData);
            % Time delay signal
            offsetData = varDelay(noisyData, k/frameSize*timingOffset);
            %% Phase offset signal
            phaseOffsetData = pfo(offsetData);
            % Filter signal
            filteredData             = RxFlt(offsetData);
            filteredDataWPhaseOffset = RxFlt(phaseOffsetData);
            filteredDataRef = RxFltRef(noisyData);

            %% Correct timing offset
            %filteredDataCorrected       = symbolSync(filteredData);
            filteredDataWPhaseCorrected = symbolSync(filteredDataWPhaseOffset);

            % Visualize Error as constellation plots - this can be commented out as needed
            %cdPre(filteredDataRef);cdPost(filteredData);cdPostCorrect(filteredDataSymbolSync);pause(0.1); %#ok<*UNRCH>
        end

        %% Calculate various EVMs:
        %BaselineEVM(snrValInd)                    = evm(filteredData);
        BaselineEVMWPhaseOffset(snrValInd)        = evm(filteredDataWPhaseOffset);
        %TimingCorrectedEVM(snrValInd)             = evm(filteredDataCorrected);
        TimingCorrectedEVMWPhaseOffset(snrValInd) = evm(filteredDataWPhaseCorrected);
    end

    %% Set up figures
    figPlot = figure;
    figName = sprintf('MATLAB_4.6_beforeCorrection_phaseOffset%.2f', currentPhaseOffset);
    scatter(snr, BaselineEVMWPhaseOffset, 100);
    title(sprintf('Uncorrected timing error EVM with phase offset = %.2f radians', currentPhaseOffset));
    xlabel('SNR (dB)');
    ylabel('EVM (% RMS of received signal)');
    text(snr+.2,BaselineEVMWPhaseOffset+.2,string(BaselineEVMWPhaseOffset))

    %% Save figure
    saveas(figPlot, strcat(figName, '.fig'));
    saveas(figPlot, strcat(figName, '.jpg'));

    figPlot = figure;
    figName = sprintf('MATLAB_4.6_afterCorrection_phaseOffset%.2f', currentPhaseOffset);
    scatter(snr, TimingCorrectedEVMWPhaseOffset, 100);
    title(sprintf('Corrected timing error EVM with phase offset = %.2f radians', currentPhaseOffset));
    xlabel('SNR (dB)');
    ylabel('EVM (% RMS of received signal)');
    text(snr+.2,TimingCorrectedEVMWPhaseOffset+.2,string(TimingCorrectedEVMWPhaseOffset));

    %% Save figure
    saveas(figPlot, strcat(figName, '.fig'));
    saveas(figPlot, strcat(figName, '.jpg'));
end