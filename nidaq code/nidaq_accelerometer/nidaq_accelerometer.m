%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
Modified version of the accelerometer plotting script use with NI USB-6001
%}

%{
Global Variables
%}
fs = 300;           % Sampling rate
fc = 5;             % Cutoff frequency for butterworth filter
global acc_buffer;  % Preallocate empty buffer arrays
acc_buffer = [];
global ts_buffer;
ts_buffer = [];

%{
Main Function Calls
%}
daqSetup(fs, fc);

%{
Function Definitions
%}
function daqSetup(fs, fc)
    % Figure and filter Setup:
    [~, ax] = figSetup();
    [b,a] = butter(3, fc/(fs/2), "low");

    % NI DAQ Setup:
    d = daq("ni");                       % NI USB-6001 device
    addinput(d,'Dev15','ai0','Voltage'); % accelerometer x-data
    addinput(d,'Dev15','ai4','Voltage'); % accelerometer y-data
    d.Rate = fs;

    % Arduino Setup:
    ard = serialport("/dev/cu.usbmodem101", 115200); % Connected USB (Arduino)
    configureTerminator(ard, "LF");
    flush(ard);
        
    % Callback Setup
    sec_to_plot = 3;
    d.ScansAvailableFcnCount = fs/10;
    d.ScansAvailableFcn = @(src, evt) plotFcn(src, evt, ax, fs, b, a, ard, sec_to_plot);
    
    % Start Acquisition
    start(d, 'continuous');

    % Hold until button press
    waitforbuttonpress();

    % DAQ Cleanup
    stop(d)
    flush(d)
end

function plotFcn(src, ~, ax, fs, b, a, ard, sec_to_plot)
    % Callback function for plotting when available

    global acc_buffer;
    global ts_buffer;

    % Obtain data:
    [data, ts, ~] = read(src, src.ScansAvailableFcnCount, OutputFormat='Matrix');
    if ard.NumBytesAvailable > 0
        line = readline(ard);
    end

    try
        % Data preparation:
        x_data = (data(:,1) - 3/2) ./ 0.42;
        y_data = (data(:,2) - 3/2) ./ 0.42;
        acc = sqrt(x_data.^2 + y_data.^2); 

        ard_data = str2double(split(line, ','));
        ard_readtime = ts(1);
        % Receive ard data in the format: 
        % [spo2_value, PPG_buffer]
        spo2 = ard_data(1);
        fprintf("SpO2 value: %.2f", spo2);
        ppg_buffer = ard_data(2:end);
        % heartrate detection fcn call
        hr = getHeartrate(ppg_buffer);
        fprintf("Heart rate: %.2f", hr)

        persistent z;
        if isempty(z)
            z = [];
        end
        [acc_filt,z] = filter(b,a,acc,z);

        acc_buffer = [acc_buffer; acc_filt];
        ts_buffer  = [ts_buffer; ts];



        % Plotting:

        plot(ax, ts, acc_filt, 'k-', LineWidth = 1.5); hold(ax, 'on');

        xlim([ts_buffer(end-sec_to_plot*fs), ts_buffer(end)]);
        ylim("tight");
        drawnow limitrate;
    catch
        persistent debug_i;
        if isempty(debug_i)
            debug_i = 0;
        end

        debug_i = debug_i + 1;
        fprintf("\nError geting or plotting data. Try: %f", debug_i)
    end

    if length(ts_buffer) >= fs*(sec_to_plot+1)
        % Clear plot and shift buffer one second over

        ts_buffer = ts_buffer((fs+1):((sec_to_plot+1)*fs));
        acc_buffer = acc_buffer((fs+1):((sec_to_plot+1)*fs));
        
        %getCadence(); % function call for cadence algo with the 5s
        %of data

        cla(ax);
        %fprintf("Cleared ax")
        plot(ax, ts_buffer, acc_buffer, 'b-');

    end

end

function [fig, ax] = figSetup()
    % Create figure and axes objects

    fig = figure();
    ax = gca;
    title(ax, "Accelerometer Data Acquisition")
    xlabel(ax, "Time (s)")
    ylabel(ax, "Acceleration (g's)")
    hold(ax, 'on');
end

function cadence = getCadence(ts, acc)
    % Calculate cadence in steps per minute

    thres_multiplier = 1;

    thres = thres_multiplier * std(acc);
    [pks, pkids] = findpeaks(acc, 'MinPeakProminence', thres);
    cadence = 60/mean(diff(ts(pkids)));
end

function hr = getHeartrate(ppg)
    % Calculate the heart rate in beats per minute
    % need to extrapolate a ts 

    % Local vars:
    thres_multiplier = 1;   % Threshold multiplier
    fs = 400;               % Arduino sample rate

    % Each ppg buffer should be fs samples long?

    % Use the mean of the first and last 25s to establish a linear gradient
    % Use this gradient to eliminate low-frequency drift
    start_avg = mean(ppg(1:25));
    end_avg = mean(ppg((end-25:end)));

    ts = (0:length(ppg)-1) / fs;

    drift_slope = (end_avg - start_avg) / ts(end);
    
    for i = 1:length(ppg)
        ppg(i) = ppg(i) + ts(i)*drift_slope;
    end

    % lowpass filter? could that just do the job of the "drift correction"

    % Peak detection:
    thres = thres_multiplier * std(ppg);
    [pks, pkids] = findpeaks(ppg, 'MinPeakDistance', ppg);
    hr = 60/mean(diff(ts(pkids)));
end


