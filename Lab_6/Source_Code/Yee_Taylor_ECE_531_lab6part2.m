%% Lab 1 Part 2: Fine Frequency Correction
clear all; close all;

% Debugging flags
visuals = false;

%% General system details
sampleRateHz = 1e3; % Sample rate
samplesPerSymbol = 1;
frameSize = 2^10;
numFrames = 300;
numSamples = numFrames*frameSize; % Samples to simulate

%% Setup objects
mod = comm.DBPSKModulator();
cdPre = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'Name','Baseband');
cdPost = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'SymbolsToDisplaySource','Property',...
    'SymbolsToDisplay',frameSize/2,...
    'Name','Baseband with Freq Offset');
cdCorrected = comm.ConstellationDiagram('ReferenceConstellation', [-1 1],...
    'SymbolsToDisplaySource','Property',...
    'SymbolsToDisplay',frameSize/2,...
    'Name','Baseband with Freq Offset FFC Corrected');
cdPre.Position(1) = 50;
cdPost.Position(1) = cdPre.Position(1)+cdPre.Position(3)+10;% Place side by side
cdCorrected.Position(1) = cdPre.Position(1)+cdPre.Position(3)+50;
ap = dsp.ArrayPlot;ap.ShowGrid = true;
ap.Title = 'Frequency Histogram';ap.XLabel = 'Hz';ap.YLabel = 'Magnitude';
ap.XOffset = -sampleRateHz/2;
ap.SampleIncrement = (sampleRateHz)/(2^10);

%% Impairments
snr = 15;
frequencyOffsetHz = sampleRateHz*0.02; % Offset in hertz
phaseOffset = pi/8; % Radians

%% Generate symbols
data = randi([0 samplesPerSymbol], numSamples, 1);
modulatedData = mod.step(data);

%% Setup Fine Frequency Compensator
fineFreqComp = comm.CarrierSynchronizer('Modulation','BPSK', ...
    'SamplesPerSymbol',samplesPerSymbol, 'CustomPhaseOffset',phaseOffset);

%% Add error vector magnitude (EVM)
evm = comm.EVM('ReferenceSignalSource','Estimated from reference constellation');

%% Add noise
noisyData = awgn(modulatedData,snr);%,'measured');

%% Model of error
% Add frequency offset to baseband signal

% Precalculate constants
normalizedOffset = 1i.*2*pi*frequencyOffsetHz./sampleRateHz;

offsetData    = zeros(size(noisyData));
fineCorrectedData = zeros(size(noisyData));
correctedPhaseEstimate = zeros(size(noisyData));

for k=1:frameSize:numSamples
    
    timeIndex = (k:k+frameSize-1).';
    freqShift = exp(normalizedOffset*timeIndex + phaseOffset);
    
    % Offset data and maintain phase between frames
    offsetData(timeIndex) = noisyData(timeIndex).*freqShift;

    % Next, correct offset data with fine frequency compensator
    [fineCorrectedData(timeIndex), correctedPhaseEstimate(timeIndex)] = fineFreqComp(offsetData(timeIndex));
    
    % Visualize Error
    if visuals
        % Compare noisy data to offset data
        %step(cdPre,noisyData(timeIndex));step(cdPost,offsetData(timeIndex));pause(0.1); %#ok<*UNRCH>

        % Compare corrected data to offset data
        step(cdPre,noisyData(timeIndex));step(cdCorrected,fineCorrectedData(timeIndex));step(cdPost,offsetData(timeIndex));pause(0.1); %#ok<*UNRCH>

        % Compare noisy data to corrected data
        %step(cdPre,noisyData(timeIndex));step(cdPost,correctedData(timeIndex));pause(0.1); %#ok<*UNRCH>

    end
    
end

rmsEVM = evm(correctedPhaseEstimate)