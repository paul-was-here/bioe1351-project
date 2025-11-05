function cadence = cadenceFcn(ts, acc)
    % Detect cadence from input data
    % 
    % Inputs:   ts  (time vector)
    %           acc (acceleration vector)
    %
    % Returns cadence in steps/min
    %
    % Note that input acc is pre-filtered in the main function.

    thres = 1*std(acc);
    [~, pkids] = findpeaks(acc, 'MinPeakProminence', thres);
    cadence = 60/mean(diff(ts(pkids)));
    return
end