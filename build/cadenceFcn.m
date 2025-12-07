function cadence = cadenceFcn(ts, acc)
    % Detect cadence from input data
    % 
    % Inputs:   ts  (time vector)
    %           acc (acceleration vector)
    %
    % Returns cadence in steps/min
    %
    % Note that input acc is pre-filtered in the main function.

    detection_method = "peakprominence";
                % Options: "fft" or "peakprominence"

    if detection_method == "peakprominence"
        thres = 1*std(acc);
        [~, pkids] = findpeaks(acc, 'MinPeakProminence', thres);
        cadence = 60/mean(diff(ts(pkids)));
        return
    elseif detection_method == "fft"
        
        % written incorrectly and depracated. fft-based accelerometry
        % analysis is in another function within the app itself
    end
end