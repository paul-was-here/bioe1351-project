%{
Author: Paul Kullmann
BIOENG 1351/2351 Project

Loads a saved recording and permits step-by-step viewing of the signal.
Use this script to evaluate the accuracy of the algorithms designed in
heartRateFcn.m.
%}

x = load('good form ppg.mat');
figure()

d = designfilt('highpassiir', ...
                'FilterOrder', 3, ...
                'HalfPowerFrequency', 0.4, ...
                'SampleRate', 20, ...
                'DesignMethod', 'Butter');

for i = 1:100:length(x.ppg_datasave(:,1))
    ts = x.ppg_datasave(i:i+99, 1);
    ppg = x.ppg_datasave(i:i+99, 2);
    
    globalstep = ts(end);

    pause;
    cla;

    ts = ts-ts(1);
    
    yyaxis right;
    cla;
    plot(ts, ppg, 'b-'); hold on;
    yyaxis left;

    
    hr = heartRateFcn(ts, ppg, d);
    fprintf("\nHR (peak detection method: %.2f", hr);   
    fprintf("\nGlobal step: %.2f\n\n", globalstep)
end


