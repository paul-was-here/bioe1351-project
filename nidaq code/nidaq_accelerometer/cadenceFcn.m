function cadence = cadenceFcn(ts, acc)
    % Detect cadence from input data
    % 
    % Inputs:   ts  (time vector)
    %           acc (acceleration vector)
    %
    % Returns cadence in steps/min
    %
    % Note that input acc is pre-filtered in the main function.

    detection_method = "fft";
                % Options: "fft" or "peakprominence"

    if detection_method == "peakprominence"
        thres = 1*std(acc);
        [~, pkids] = findpeaks(acc, 'MinPeakProminence', thres);
        cadence = 60/mean(diff(ts(pkids)));
        return
    elseif detection_method == "fft"
        % Variables setup:
        L = length(acc);
        fs = length(acc)/(ts(end)-ts(1)); 

        % Compute FFT:
        Y = fft(acc);
        P2 = abs(Y/L);          % Two-sided FFT
        P1 = P2(1:L/2+1);       % One-sided FFT
        f = fs * (0:(L/2)) / L; % Frequency vector

        % Window FFT to relevant frequencies
        [~, min_freq_idx] = min(abs(f - 0.5));
        [~, max_freq_idx] = min(abs(f-5));
        f_window = f(min_freq_idx:max_freq_idx);    % Adjust to frequency window of interest
        f_order = sort(f_window, 'descend');        % Sort by descending frequency

        cadence = 60*f_order(1); % Assume most prominent frequency is the step
        
        % Assume second most prominent frequency in y is up-down bobbing
        if f_order(2)/f_order(1) > 0.5
            fprintf("\nBobbing up and down detected: Attempt to reduce" + ...
                "bobbing motion.")
        end

    end
end