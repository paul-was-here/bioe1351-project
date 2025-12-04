%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
Modified version of the accelerometer plotting script use with NI USB-6001
%}

%{
Global Variables
%}
fs = 300;           % Sampling rate
fc = 10;             % Cutoff frequency for butterworth filter
global acc_buffer;  % Preallocate empty buffer arrays
acc_buffer = [];
global ts_buffer;
ts_buffer = [];

global acceler_datasave;
acceler_datasave = [];

global ard_ts_buffer;
ard_ts_buffer = [];
global ard_ppg_buffer;
ard_ppg_buffer = [];

global ppg_datasave;
ppg_datasave = [];


global starttime;
starttime = datetime("now");

%{
Main Function Calls
%}
daqSetup(fs, fc);

%{
Function Definitions
%}
function daqSetup(fs, fc)
    global ppg_datasave;
    global acceler_datasave;

    % Figure and filter Setup:
    [~, ax] = figSetup();                   % Get ax objects
    [b,a] = butter(3, fc/(fs/2), "low");    % Create filter coeffs
    d_hr = designHeartRateFilter();

    % NI DAQ Setup:
    d = daq("ni");                          % NI USB-6001 device
    addinput(d,'Dev15','ai0','Voltage');     % ->Accelerometer x-data
    addinput(d,'Dev15','ai4','Voltage');     % ->Accelerometer y-data
    d.Rate = fs;                            % Set sampling rate

    % Arduino Setup:
    ard = serialport("COM4", 230400);       % Connected USB (Arduino)
    configureTerminator(ard, "LF");
    flush(ard);
        
    % Callback Setup
    sec_to_plot = 8;                        % Seconds to plot
    d.ScansAvailableFcnCount = fs/10;       % Effective plot refresh rate 
    d.ScansAvailableFcn = @(src, evt) plotFcn(src, evt, ax, fs, b, a, ard, sec_to_plot, d_hr);
    
    % Start Acquisition
    start(d, 'continuous');

    % Run until button press
    waitforbuttonpress();

    % DAQ Cleanup
    stop(d)
    flush(d)
    save("saved_ppg_data.mat","ppg_datasave")
    save("saved_acc_data.mat", "acceler_datasave")
end

function plotFcn(src, ~, ax, fs, b, a, ard, sec_to_plot, d_hr)
    % Callback function for plotting when available

    global acc_buffer;
    global ts_buffer;
    global starttime;
    global ard_ppg_buffer;
    global ard_ts_buffer;
    global acceler_datasave;

    global ppg_datasave;

    %% NI DAQ Data Acquisition:
    [data, ts, ~] = read(src, src.ScansAvailableFcnCount, OutputFormat='Matrix');
    try
        % Data preparation:
        x_data = (data(:,1) - 3/2) ./ 0.42;
        y_data = (data(:,2) - 3/2) ./ 0.42;
        acc = sqrt(x_data.^2 + y_data.^2); 

        acceler_datasave = [acceler_datasave; ts, x_data, y_data];

        % Filtering:
        persistent z;   % Persistent filter history variable (smooths data)
        if isempty(z)
            z = [];
        end
        [acc_filt,z] = filter(b,a,acc,z);

        % Save to plotting buffer:
        acc_buffer = [acc_buffer; acc_filt];
        ts_buffer  = [ts_buffer; ts];

        % Plotting:
        yyaxis left;
        plot(ax, ts, acc_filt, 'k-', LineWidth = 1.5); hold(ax, 'on');
        if ts_buffer(end) < sec_to_plot
            xlim([0 sec_to_plot])
        else
            xlim([ts_buffer(end-sec_to_plot*fs), ts_buffer(end)]);
        end
        ylim("tight");
        drawnow limitrate;
    catch
        % Debug catch

        % right now an exception is raised each time the plot tries to update xlim
        % until t >= sec_to_plot. not really critical in any way
        % ts_buffer(end-sec_to_plot*fs) dne for t < sec_to_plot

        persistent debug_i;
        if isempty(debug_i)
            debug_i = 0;
        end

        debug_i = debug_i + 1;
        fprintf("\nError geting or plotting data. Try: %f", debug_i)
    end

    %% Arduino Data Acquisition:
    if ard.NumBytesAvailable > 0
        line = readline(ard);
        %disp("raw line: ")  % Debug
        %disp(line)          % Debug
        try
            ard_data = str2double(split(line, ','));
            ard_readtime = seconds(datetime("now") - starttime);
                    % consider correlation to NI DAQ timestamp instead
            % Receive ard data in the format: 
            % [ppg_buffer (array), spo2 (float)]

            spo2 = ard_data(end);
            fprintf("\nSpO2 value: %.2f", spo2);

            ppg_buffer = -1 * ard_data(1:(end-1));

            % Local Arduino settings:
            ard_sample_rate = 100;               % Sampling rate 
            ard_samples_per_value = 5;           % # samples averaged per value
            ard_fs = ard_sample_rate/ard_samples_per_value;

            ts_start = ard_readtime - (length(ppg_buffer) - 1)/ard_fs;
            ts_ard = linspace(ts_start, ard_readtime, length(ppg_buffer));
            % Since we are retroactively receiving data from the past few s,
            % assign ard_readtime as the timestamp for the LAST value

            %ard_ts_buffer = [ard_ts_buffer, ts_ard];
            %ard_ppg_buffer = [ard_ppg_buffer, ppg_buffer];

            ppg_datasave = [ppg_datasave; [ts_ard(:) ppg_buffer(:)]];
            
            % Create a valid timestamp string for the filename
            fname = datestr(now, 'yyyymmdd_HHMMSS');  % e.g. '20251102_154530'
            fname = [fname '.mat'];
            %save(fname, 'ts_ard', 'ppg_buffer');

            yyaxis right;
            cla(ax);
            plot(ax, ts_ard, ppg_buffer, 'r-'); hold on;
            ylim(ax, "tight");

            hr = heartRateFcn(ts_ard, ppg_buffer, d_hr);
            fprintf("\nComputed heart rate: %.2f", hr);

            drawnow limitrate;
        catch ME
            fprintf("\n\tError in arduino data acquisition:");
            fprintf("\n\tMessage: %s", ME.message);
        end
    end

    %% Plot Buffer Clearing:
    if length(ts_buffer) >= fs*(sec_to_plot+1)
        % Use currently plotted data to compute cadence before clearing
        cadence = cadenceFcn(ts_buffer, acc_buffer);
        fprintf("\nComputed cadence: %.2f steps/min", cadence)

        % Shift accelerometer buffer 1s over:
        ts_buffer = ts_buffer((fs+1):((sec_to_plot+1)*fs));
        acc_buffer = acc_buffer((fs+1):((sec_to_plot+1)*fs));

        %ard_ts_buffer = ard_ts_buffer(end-100:end);
        %ard_ppg_buffer = ard_ppg_buffer(end-100:end);
        
        cla(ax);
        yyaxis left;
        plot(ax, ts_buffer, acc_buffer, 'b-');
        %yyaxis right;
        %cla(ax);
        %plot(ax, ard_ts_buffer, ard_ppg_buffer, 'r-');
    end
end

function [fig, ax] = figSetup()
    % Create figure and axes objects

    fig = figure();
    ax = gca;
    title(ax, "Data Acquisition")
    xlabel(ax, "Time (s)")
    ylabel(ax, "Acceleration (g's)")
    hold(ax, 'on');
end

function d_hr = designHeartRateFilter()
    % Design a highpass filter for heartrate PPG data
    % Returns digital filter object d_hr

    Fs = 20;
    Fc = 0.4;

    d_hr = designfilt('highpassiir', ...
        'FilterOrder', 3, ...
        'HalfPowerFrequency', Fc, ...
        'SampleRate', Fs, ...
        'DesignMethod', 'Butter');
end