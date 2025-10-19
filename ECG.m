%% BIOENG 1351
% Lab 5

% Function calls:
startPPG() % To begin a new recording
%plotSavedData() % Tdo just plot an existing recording
%peakDetectSavedData() % To plot peak detection + pulse metrics for existing recording

function startPPG()
    % Starts and saves a new recording

    global datasave % Create global datasave array
    datasave = []; % Pre-allocate empty data array
    global bstopd
    bstopd = [];

    % Plot and DAQ setup:
    [figDispaly, Vplot] = figSetup(); % Calls figSetup to get plot and ax objects
    adi = daq("adi"); % Add DAQ to adi object
    addinput(adi,'smu1','a','Voltage'); % Add input V channel on a
    adi.ScansAvailableFcnCount = 2*adi.Rate; % Set number of scans per callback
    adi.ScansAvailableFcn = @(src,evt) plotPPG(src, evt, Vplot); % Callback function
    start(adi, 'continuous'); % Starts adi in background mode

    % Run until ended by user:
    flag='no'; % Set initial flag to compare against
    while strcmp(flag,'no') % Loop until input =/= 'no'
        flag=input(['quit?'],'s'); % Get user input   
    end
    
    % Stop & Save Commands:
    stop(adi); % stop daq
    flush(adi); % clear data in daq buffer
    save('PPGData','datasave'); % save data recorded from DAQ
end

function plotPPG(src, ~, Vplot)
    % Callback function for when the DAQ has enough data

    global datasave % Get global datasave variable
    global bstopd

    [data, ts, ~] = read(src, src.ScansAvailableFcnCount,"OutputFormat", "Matrix"); % Read data on callback prompt
    
    fs = src.Rate; % Gets frequency as daq rate
    wn = 25/(fs/2); % Sets cutoff frequency for filter
    %[b,a] = butter(1,wn,'low'); % Creates butterworth filter
    %filtered = filtfilt(b,a,data); % Performs butterwoth filter operation
    %d = designfilt('bandpassiir','filterorder',4,'HalfPowerFrequency1',13,'HalfPowerFrequency2',30,'SampleRate',fs); % Designs a 2nd order IIR bandpass for 13-30Hz
    
    dx = data - 3.3/2;
    
    bstop = designfilt('bandstopiir', ...
        FilterOrder=6, ...
        HalfPowerFrequency1=55, ...
        HalfPowerFrequency2=65, ...
        SampleRate=fs);

    bstopfiltd = filtfilt(bstop, dx);

    d = designfilt('bandpassiir', ...
        FilterOrder=4, ...
        HalfPowerFrequency1=0.05, ...
        HalfPowerFrequency2=120, ...
        SampleRate=fs);

    filtered = filtfilt(d, bstopfiltd);

    %bstopd = [bstopd; bstopfiltd];

    %filtered = filtfilt(d, bstopd);

    %datasave = [datasave; ts(10000:end) filtered(10000:end) data(10000:end)]; %Saves data as: col 1 timestamp, 2 filtered, 3 raw data
    cla(Vplot.axV); % Clears current plot
    plot(Vplot.axV, ts, filtered, 'k-') % Plots new interval of data on the plot
end

function [figDisplay, Vplot]= figSetup()
    % Creates and returns figure and ax objects

    figDisplay = figure(); % Creates nwe figure
    Vplot = {}; % Sets Vplot as an obejct
    Vplot.axV = gca; % Sets current ax as Vplot
    hold(Vplot.axV, 'on'); % Holds plot on
    xlabel(Vplot.axV, 'Time (s)'); % Sets x-axis label
    ylabel(Vplot.axV, 'Voltage (V)'); % Sets y-axis label
    % ylim(Vplot.axV, [-2 2])
    ylim(Vplot.axV, "tight")
end

function plotSavedData
    % Plots a saved recording

    % Load data:
    ppg = load("PPGData.mat"); % Loads saved PPG data
    x = ppg.datasave(:,1); % Sets time to x var
    y = ppg.datasave(:,2); % Sets filtered voltage to y var

    % Plotting:
    figure() % Creates new figure
    plot(x,y,'k-'); % Plots the filtered waveform
    xlabel("Time (s)") % Creates x-axis label
    ylabel("Voltage (V)") % Creates y-axis label
    title("Filtered PPG Data"); % Creates plot title
    legend('Filtered PPG Signal'); % Creates plot legend
end

function peakDetectSavedData
    % Plot a saved recording + peak detection & pulse metrics

    % Load data:
    ppg = load("PartC_Saved_PPG.mat"); % Loads saved PPG data
    x = ppg.datasave(:,1); % Assigns time to x var
    y = ppg.datasave(:,2); % Assigns filtered voltage to y var

    % Peak detection:
    thres = 3*std(y); % Sets the threshold as 3x the standard deviation of the signal amplitude
    [pks, pkids] = findpeaks(y, 'MinPeakProminence', thres, 'MinPeakWidth', 100); % Finds the peaks and their indexes

    % Plotting:
    figure() % Creates new figure
    plot(x,y,'k-'); % Plots filtered PPG data
    hold on; % Holds plot to overlay
    plot(x(pkids), pks, 'or'); % Plots the peaks as red circles
    title("Filtered PPG Data with Peak Detection"); % Sets plot title
    xlabel("Time (s)"); % Creates x-axis label
    ylabel("Voltage (V)"); % Creates y-axis label
    legend('Filtered PPG Signal','Waveform Peaks'); % Creates legend
    
    % Calculate statistics:
    avg_HR = length(pkids) / max(x) * 60; % Computers avg HR/min as # peaks / max(time) * 60s
    RR_interval = diff(x(pkids)); % Calculate RR intervals from peak indices
    avg_RR = mean(RR_interval); % Compute average RR interval
    RR_std = std(RR_interval); % Computer R-R interval standard deviation
    
    % Print statistics:
    fprintf('Average Heart Rate: %.2f bpm\n', avg_HR); % Display avg HR
    fprintf('Average RR Interval: %.2f seconds\n', avg_RR); % Display avg RR interval
    fprintf('Standard Deviation of RR Interval: %.2f seconds\n', RR_std); % Display RR stdev
end