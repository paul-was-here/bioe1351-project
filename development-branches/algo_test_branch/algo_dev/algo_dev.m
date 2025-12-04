
%% heartrte:
hr_vector = linspace(0,220,220);
target_hr = 180;
S_hr = normpdf(hr_vector, target_hr, 10);
S_hr = S_hr/(0.5*max(S_hr)) - 1;

figure();
plot(hr_vector, S_hr); hold on;
xline(target_hr, 'k--');
yline(0, 'k-');
legend("HR Mapping Curve", "Target HR", "");
xlabel("Heart rate (bpm)");
ylabel('Performance Score S_h_r');
title("Heart Rate Mapping Example - μ=180, σ=10");

%% spo2:
spo2_vector = linspace(0,100,101);
s_spo2 = [-1*ones(1,90), linspace(-1,1,6) ,ones(1,5)];
figure();
plot(spo2_vector, s_spo2); hold on;
ylim([-1.2 1.2])
xlabel("SpO2 (%)");
ylabel('Performance Score S_s_p_o_2');
yline(0, 'k-');
title("SpO2 Mapping Example");

%% cadence:
cadence_vector = linspace(0,250,250);
target_cadence = 180;
S_cadence = normpdf(cadence_vector, target_cadence, 30);
S_cadence = S_cadence/(0.5*max(S_cadence)) - 1;
figure();
plot(cadence_vector, S_cadence); hold on;
yline(0, 'k-');
xline(target_cadence, 'k--');
legend("Cadence Mapping Curve", "Target Cadence", "");
xlabel("Cadence (step/min)");
ylabel('Performance Score S_c_a_d');
title("Cadence Mapping Example - μ=180, σ=30");

%% bobbing:
bobbing_vector = linspace(0,1,500);
S_bobbing = -2./(1+exp(-10*(bobbing_vector-0.5)))+1;
figure();
plot(bobbing_vector,S_bobbing); hold on;
yline(0, 'k-');
xlabel("Bobbing Ratio (1st f / 2nd Highest f)");
ylabel("Performance Score S_b_o_b_b_i_n_g");
title("Bobbing Mapping Example");
