function baseline = calibrateAccelerometerFcn(ts, acc, baseline_pace)
    % Function to determine the baseline slope value and correlate it with a pace
    %
    % Inputs:     ts : Time vector for calibration sample
    %            acc : Filtered acceleration vector for calibration sample
    %  baseline_pace : Baseline pace to calibrate to (min/mile)
    %
    % Returns baseline in units of pace/slope. Multiply by slope at any
    % instant to obtain instantaneous pace.

    intgrl = cumtrapz(acc);
    fit = polyfit(ts, intgrl, 1);
    baseline = baseline_pace/fit(1);
end

%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
%}