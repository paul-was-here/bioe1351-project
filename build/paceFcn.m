function pace = paceFcn(ts, acc, baseline)
    % Function to determine the baseline slope value and correlate it with a pace
    %
    % Inputs:     ts : Time vector for sample
    %            acc : Filtered acceleration vector for sample
    %       baseline : Baseline from calibration in units of pace/slope
    %
    % Returns pace as a multiple of the pace used during calibration, based
    % on the slope of the current ts,acc dataset.

    intgrl = cumtrapz(acc);
    fit = polyfit(ts, intgrl, 1);
    pace = baseline*fit(1);
end

%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
%}