
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
cdPre.Position(1) = 50;
cdPost.Position(1) = cdPre.Position(1)+cdPre.Position(3)+10;% Place side by side
%% Impairments
snr = 15; %% todo: update and loop through this with SNR = 5dB, 10dB, 15dB, 20dB.
phaseOffset  = pi/8; % radians
pfo          = comm.PhaseFrequencyOffset('PhaseOffset', rad2deg(phaseOffset), 'SampleRate', sampleRateHz);
timingOffset = samplesPerSymbol*0.01; % Samples

%% Generate symbols
data = randi([0 modulationOrder-1], numSamples*2, 1);
mod = comm.DBPSKModulator(); modulatedData = mod(data);
%% Add TX/RX Filters
TxFlt = comm.RaisedCosineTransmitFilter(...
    'OutputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan);
RxFlt = comm.RaisedCosineReceiveFilter(...
    'InputSamplesPerSymbol', samplesPerSymbol,...
    'FilterSpanInSymbols', filterSymbolSpan,...
    'DecimationFactor', samplesPerSymbol);
RxFltRef = clone(RxFlt);
%% Add noise source
chan = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',snr, ...
    'SignalPower',1,'RandomStream', 'mt19937ar with seed');
%% Add delay
varDelay = dsp.VariableFractionalDelay;

%% Add error vector magnitude (EVM)
evm = comm.EVM;

%% TED-specific variables initialized here
TriggerHistory    = [];
InterpFilterState = zeros(1, 3);
Trigger           = 0;
mu                = 0;
LoopFilterState   = 0;
LoopPreviousInput = 0;
ProportionalGain  = 0.1; % Tune as needed
IntegratorGain    = 0.1; % Tune as needed

%% Model of error
% Add timing offset to baseband signal
filteredData = [];
for k=1:frameSize:(numSamples - frameSize)
    timeIndex = (k:k+frameSize-1).';
    % Filter signal
    filteredTXData = TxFlt(modulatedData(timeIndex));
    % Pass through channel
    noisyData = chan(filteredTXData);
    % Time delay signal
    offsetData = varDelay(noisyData, k/frameSize*timingOffset);
    % Phase offset signal
    phaseOffsetData = pfo(offsetData);
    % Filter signal
    filteredData = RxFlt(offsetData);filteredDataRef = RxFltRef(noisyData);

    %% Everything else here is new: implement TED here:
    
    %% Block 1: Interpolator (interpFilter.m)
    %% Receives input from both matched filter and controller, feeds out to
    %% both TED and subsequent data points
    % Define interpolator coefficients
    alpha = 0.5;
    InterpFilterCoeff = ...
        [ 0,       0,         1,       0;    % Constant
        -alpha, 1+alpha, -(1-alpha), -alpha; % Linear
        alpha,  -alpha,    -alpha,   alpha]; % Quadratic
    % Filter input data
    ySeq = [filteredData(k); InterpFilterState]; % Update delay line
    % Produce filter output
    filtOut = sum((InterpFilterCoeff * ySeq) .* [1; mu; mu^2]);
    InterpFilterState = ySeq(1:3); % Save filter input data
    
    
    %% Block 2: TED (zcTED.m) - using zero-crossing method
    % ZC-TED calculation occurs on a strobe
    if Trigger && all(~TriggerHistory(2:end))
        % Calculate the midsample point for odd or even samples per symbol
        t1 = TEDBuffer(end/2 + 1 - rem(samplesPerSymbol,2));
        t2 = TEDBuffer(end/2 + 1);
        midSample = (t1+t2)/2;
        e = real(midSample)*(sign(real(TEDBuffer(1)))-sign(real(filtOut))) + ...
            imag(midSample)*(sign(imag(TEDBuffer(1)))-sign(imag(filtOut)));
    else
        e = 0;
    end
    % Update TED buffer to manage symbol stuffs
    switch sum([TriggerHistory(2:end), Trigger])
        case 0
            % No update required
        case 1
            % Shift TED buffer regularly if ONE trigger across samplesPerSymbol samples
            TEDBuffer = [TEDBuffer(2:end), filtOut];
        otherwise % > 1
            % Stuff a missing sample if TWO triggers across samplesPerSymbol samples
            TEDBuffer = [TEDBuffer(3:end), 0, filtOut];
    end
    
    
    %% Block 3: Loop Filter (loopFilter.m)
    % Loop filter
    loopFiltOut = LoopPreviousInput + LoopFilterState;
    g = e*ProportionalGain + loopFiltOut; % Filter error signal
    LoopFilterState = loopFiltOut;
    LoopPreviousInput = e*IntegratorGain;
    % Loop filter (alternative with filter objects)
    lf = dsp.BiquadFilter('SOSMatrix',tf2sos([1 0],[1 -1])); % Create filter
    g = lf(IntegratorGain*e) + ProportionalGain*e; % Filter error signal
    
    
    
    %% Block 4: Controller (interpControl.m) - this also feeds back into Block 1
    % Interpolation Controller with modulo-1 counter
    d = g + 1/samplesPerSymbol;
    TriggerHistory = [TriggerHistory(2:end), Trigger];
    Trigger = (Counter < d); % Check if a trigger condition
    if Trigger % Upate mu if a trigger
        mu = Counter / d;
    end
    Counter = mod(Counter - d, 1); % Update counter
    % Visualize Error - this can be commented out as needed
    %cdPre(filteredDataRef);cdPost(filteredData);pause(0.1); %#ok<*UNRCH>
end

[testRMSEVM, testMaxEVM, pctEVM] = evm(filteredDataRef, filteredData);