function hr = heartRateHahn(ts, ppg)
    % 1. Performs a Hann window operation on the PPG signal
    % 2. Checks for noise and rejects measurement if window is nosiy
    % 3. Computes heart rate if signal is clean
    %
    % Inputs:   ts  (Time vector)
    %           ppg (PPG vector)
    %
    % Returns heart rate in BPM

    % Threshold settings (in *StDevs)
    noise_rejection_threshold =         2.5;
    peak_detection_threshold =          1.5;

    % Filter operations:
    [b,a] = butter(3, 0.4/20, "high");
    filt = filtfilt(b,a,ppg);
    filt = filt .* tukeywin(length(filt),0.25);

    yyaxis right;
    plot(ts, ppg, 'b-');

    yyaxis left;
    plot(ts, filt, 'k-');

    L = floor(length(filt));
    window = filt(L/5 : end-L/5);
    ts = ts(L/5 : end-L/5);

    plot(ts,window,'r-', LineWidth=2);

    upper_lim = noise_rejection_threshold*std(window);
    lower_lim = -1 * upper_lim;

    above_lim_idxs = find(window > upper_lim);
    below_lim_idxs = find(window < lower_lim);

    yline(upper_lim, 'r-');
    yline(lower_lim, 'r-');
    yline(peak_detection_threshold*std(window),'k--');
    yline(-1*peak_detection_threshold*std(window),'k--');

    out_of_bounds_idxs = [above_lim_idxs; below_lim_idxs];

    if isempty(out_of_bounds_idxs)
        [~, pkids] = findpeaks(window, 'MinPeakProminence', ...
            peak_detection_threshold*std(window));
        try
            hr = 60/mean(diff(ts(pkids)));
        catch
            hr = 0;
        end
        return
    else
        fprintf("\nNoise threshold exceeded, measurement rejected.")
        hr = "NaN";
        return
    end
end