function hr = heartRateFcn(ts, ppg, d)
    % Reject noise and calculate a heartrate
    %
    % Inputs:   ts (Time vector)
    %           ppg (PPG vector)
    %           d (Digital filter object)
    %
    % Returns heartrate in BPM

    % Algorithm Settings:
    noise_rejection_threshold =         2.5;   % in stdev's
    peak_detection_threshold =          1.5;   % in stdev's 
    showPlot =                          false; % for debug only      
    
    % Filter operations:
    filt = filtfilt(d,ppg);

    upper_lim = noise_rejection_threshold*std(filt);
    lower_lim = -1 * upper_lim;

    % Set ts to start at 0:
    ts = ts - ts(1);

    % Seek out all windows of the filtered signal above the noise threshold
    above_lim_idxs = find(filt > upper_lim);
    below_lim_idxs = find(filt < lower_lim);

    % Create a vertical vector of all out-of-bounds instances
    out_of_bounds_idxs = [above_lim_idxs; below_lim_idxs];

    if isempty(out_of_bounds_idxs)
        % Case 1: No data is out of bounds
        [~, pkids] = findpeaks(filt, 'MinPeakProminence', ...
            peak_detection_threshold*std(filt));
        pre_hr = 60/mean(diff(ts(pkids)));
        hr = checkBounds(pre_hr);
        if showPlot == true
            %{
            plot(ts, filt, 'r-', LineWidth = 2);
            yline(noise_rejection_threshold*std(filt), 'r');
            yline(-noise_rejection_threshold*std(filt), 'r');
            yline(peak_detection_threshold*std(filt), 'k--');
            yline(-peak_detection_threshold*std(filt), 'k--');
            %}
        end
        return
    else
        % Identify leftmost and rightmost noise event timepoints
        left_noise_lim = min(out_of_bounds_idxs);
        right_noise_lim = max(out_of_bounds_idxs);
        if ts(left_noise_lim) > 3
            % Case 2: >3s of clean signal available on left side of some
            % noise event
            ts = ts(1:left_noise_lim-30);
            filt = filt(1:left_noise_lim-30);
        elseif ts(end) - ts(right_noise_lim) > 3
            % Case 3: >3s of clean signal available on right side of some
            % noise event
            ts = ts(right_noise_lim+30:end);
            filt = filt(right_noise_lim+30:end);
        elseif ts(right_noise_lim) - ts(left_noise_lim) > 4
            % Case 4: >4s of clean signal available in middle of two noise
            % events
            ts = ts(left_noise_lim+1:right_noise_lim-1);
            filt = filt(left_noise_lim+1:right_noise_lim-1);
        else
            hr = "NaN";
            return
        end
            [~, pkids] = findpeaks(filt, 'MinPeakProminence', ...
                peak_detection_threshold*std(filt));
            pre_hr = 60/mean(diff(ts(pkids)));
            hr = checkBounds(pre_hr);
            if showPlot == true
                %{
                plot(ts, filt, 'r-', LineWidth = 2);
                yline(noise_rejection_threshold*std(filt), 'r');
                yline(-noise_rejection_threshold*std(filt), 'r');
                yline(peak_detection_threshold*std(filt), 'k--');
                yline(-peak_detection_threshold*std(filt), 'k--');
                %}
            end
            return
    end
end

%% Helper Functions:
function hr = checkBounds(in)
    % Check if heartrate is in reasonable bounds (btw 40 & 220)
    % Returns the heart rate if within bounds or NaN if out of bounds.

    if in > 220 || in < 40
        hr = "NaN";
    else
        hr = in;
    end
end