%{
Author: Paul Kullmann
BIOENG 1351/2351 Project

Loads a saved recording and permits step-by-step viewing of the signal.
Use this script to evaluate the accuracy of the algorithms designed in
heartRateFcn.m.
%}

x = load('saved_ppg_data.mat');
figure()

for i = 1:100:length(x.ppg_datasave(:,1))
    ts = x.ppg_datasave(i:i+99, 1);
    ppg = x.ppg_datasave(i:i+99, 2);

    pause;
    cla;

    ts = ts-ts(1);
    
    yyaxis right;
    cla;
    plot(ts, ppg, 'b-'); hold on;
    yyaxis left;
    
    hr = heartRateFcn(ts, ppg);
    fprintf("\nHR (peak detection method: %.2f\n\n\n", hr);
    %disp(hr);
    
end


