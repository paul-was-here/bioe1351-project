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

    % Figure and filter Setup:
    [~, ax] = figSetup();                   % Get ax objects
    [b,a] = butter(3, fc/(fs/2), "low");    % Create filter coeffs

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
    d.ScansAvailableFcn = @(src, evt) plotFcn(src, evt, ax, fs, b, a, ard, sec_to_plot);
    
    % Start Acquisition
    start(d, 'continuous');

    % Run until button press
    waitforbuttonpress();

    % DAQ Cleanup
    stop(d)
    flush(d)
    save("saved_ppg_data.mat","ppg_datasave")
end

function plotFcn(src, ~, ax, fs, b, a, ard, sec_to_plot)
    % Callback function for plotting when available

    global acc_buffer;
    global ts_buffer;
    global starttime;
    global ard_ppg_buffer;
    global ard_ts_buffer;

    global ppg_datasave;

    %% NI DAQ Data Acquisition:
    [data, ts, ~] = read(src, src.ScansAvailableFcnCount, OutputFormat='Matrix');
    try
        % Data preparation:
        x_data = (data(:,1) - 3/2) ./ 0.42;
        y_data = (data(:,2) - 3/2) ./ 0.42;
        acc = sqrt(x_data.^2 + y_data.^2); 

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
        xlim([ts_buffer(end-sec_to_plot*fs), ts_buffer(end)]);
        ylim("tight");
        drawnow limitrate;
    catch
        % Debug catch
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

            % Receive ard data in the format: 
            % [ppg_buffer (array), spo2 (float)]

            spo2 = ard_data(end);
            fprintf("\nSpO2 value: %.2f", spo2);

            ppg_buffer = -1 * ard_data(1:(end-1));

            % Local Arduino settings:
            ard_sample_rate = 100;               % Sampling rate 
            ard_samples_per_value = 5;          % # samples averaged per value
            % something abt this is weird cause the arduino is set to avg 4
            % samples value so idk lol. with 10 the timing is accurate
            ard_fs = ard_sample_rate/ard_samples_per_value;

            %ts_end = ard_readtime + (length(ppg_buffer) - 1)/ard_fs;
            ts_start = ard_readtime - (length(ppg_buffer) - 1)/ard_fs;

            ts_ard = linspace(ts_start, ard_readtime, length(ppg_buffer));
            % Since we are retroactively receiving data from the past ~1s,
            % assign ard_readtime as the timestamp for the LAST value


            %ard_ts_buffer = [ard_ts_buffer, ts_ard];
            %ard_ppg_buffer = [ard_ppg_buffer, ppg_buffer];

            ppg_datasave = [ppg_datasave; [ts_ard(:) ppg_buffer(:)]];
            
            % Create a valid timestamp string for the filename
            fname = datestr(now, 'yyyymmdd_HHMMSS');  % e.g. '20251102_154530'
            
            % Build the full filename
            fname = [fname '.mat'];
            
            % Save variables
            %save(fname, 'ts_ard', 'ppg_buffer');


            %hr = getHeartrate(ts_ard, ppg_buffer);
            %fprintf("\nHeart rate: %.2f", hr)
            fprintf('Length ts_ard: %d, Length ppg_buffer: %d\n', length(ts_ard), length(ppg_buffer));

            yyaxis right;
            cla(ax);
            plot(ax, ts_ard, ppg_buffer, 'r-'); hold on;
            ylim(ax, "tight");

            hr = heartRateFcn(ts_ard, ppg_buffer);
            fprintf("\nComputed heart rate: %.2f", hr);

            %{
            Heart rate seems accurate. maybe buffer 5-10 values and average
            them? most of the time returns a bad read (NaN) but when it
            returns a valid number, seems good.

            remove plotting stuff from the algo script

            add hard cutoffs <40 and >210 to return NaN

            returns NaN even no noise- something is wrong.also doesn't plot
            red and black lines
            %}

            drawnow limitrate;
        catch ME
            fprintf("\n Error in arduino data acquisition");
            fprintf("\nMessage: %s", ME.message);
        end
    else
        %fprintf("\n No line of Ard data available."); % Debug print
    end

    %% Plot Buffer Clearing:
    if length(ts_buffer) >= fs*(sec_to_plot+1)
        % Clear plot and shift buffer one second over

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


%% WIP functions
function cadence = getCadence(ts, acc)
    % Calculate cadence in steps per minute

    thres_multiplier = 1;

    thres = thres_multiplier * std(acc);
    [pks, pkids] = findpeaks(acc, 'MinPeakProminence', thres);
    cadence = 60/mean(diff(ts(pkids)));
end

function hr = getHeartrate(ts, ppg)
    % Reject noise and calculate a heartrate threshold

    % Algorithm Settings:
    noise_rejection_threshold =         3;
    peak_detection_threshold =          2;
    
    % Filter operations:
    [b,a] = butter(3, 0.5/10, "high");
    filt = filtfilt(b,a,ppg);

    upper_lim = noise_rejection_threshold*std(filt);
    lower_lim = -1 * upper_lim;

    % Set ts to start at 0:
    ts = ts - ts(1);

    above_lim_idxs = find(ppg > upper_lim);
    below_lim_idxs = find(ppg < lower_lim);

    if isempty(above_lim_idxs) && isempty(below_lim_idxs)
        [~, pkids] = findpeaks(filt, 'MinPeakProminence', ...
            peak_detection_threshold*std(filt));
        hr = 60/mean(diff(ts(pkids)));
    else
        left_noise_lim = min(above_lim_idxs(1), below_lim_idxs(1));
        right_noise_lim = max(above_lim_idxs(end), below_lim_idxs(end));

        if ts(left_noise_lim) > 2
            % if we have at least 2s of no noise data to the left of the
            % limit
            ts = ts(1:left_noise_lim);
            filt = filt(1:left_noise_lim);
        elseif ts(end) - ts(right_noise_lim) > 2
            % otherwise check if there are at least 2s of clean data to the
            % right of the limit
            ts = ts(right_noise_lim:end);
            filt = filt(right_noise_lim:end);
        else
            hr = "Heart rate could not be computed.";
            return
        end
        [~, pkids] = findpeaks (filt, 'MinPeakProminence', ...
            peak_detection_threshold*std(filt));
        hr = 60/mean(diff(ts(pkids))); 
    end
end

function d = createHeartrateFilter(lower_fc, upper_fc)
    % side note: should probably call this in one of the startup functions
    % so that the filter object isn't being created EVERY time it needs to
    % filter some data;

    norm_fs = 10;               % Sampling rate

    if isempty(lower_fc) || isempty(upper_fc)
        lower_fc = 0.5;
        upper_fc = 5;
    end
    
    d = designfilt("bandpassiir", ...
        FilterOrder =           3,...
        HalfPowerFrequency1 =   lower_fc,...
        HalfPowerFrequency2 =   upper_fc,...
        SampleRate =            norm_fs...
        );
end


