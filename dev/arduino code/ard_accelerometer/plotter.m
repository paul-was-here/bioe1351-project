%{
Author: Paul Kullmann
BIOENG 1351/2351 Project

Plots saved accelerometer data.
Test bench for our cadence algorithm.
%}

fs=100;

[b,a] = butter(3, 10/(fs/2));
x = load("Wrist_5min.mat");


ts = x.datasave(:,1);
acc = x.datasave(:,2) - 1.38;
%ts = x.ts-(x.ts(1));
%acc = x.acc - (mean(x.acc));
acc_filt = filtfilt(b,a,acc);

figure();
plot(ts,acc,'b-'); hold on;
plot(ts,acc_filt,'k-',LineWidth=1.5);
xlabel("Time (s)")
ylabel("Acc (g's)")

v = cumtrapz(acc_filt);
yyaxis right
plot(ts,v, 'r-', LineWidth=1.5);

z = cumtrapz(v);
%plot(ts,z,'g-',LineWidth=1.5)

% Velocity data:


rm = rms(acc_filt((66*fs):(93*fs)));
fprintf("\nRMS: %.2f", rm);
mn = mean(acc_filt((118*fs):(129*fs)));
fprintf("\n Mean: %.2f", mn);

v = cumtrapz(ts, (acc));
yyaxis right;
plot(ts, v, 'g-', LineWidth = 3)
yline(0, 'g', LineWidth=2)
yyaxis left;


% Cadence algorithm:

for t = 501:500:length(acc_filt)
    thres = 1*std(acc_filt((t-500):t));
    [pks, pkids] = findpeaks(acc_filt((t-500):t), 'MinPeakProminence', thres);
    segment_start = t-500+1;
    cadence = 60/mean(diff(ts(segment_start + pkids - 1)));
    % at faster speeds, L+R peaks get really close together and detecting
    % them gets hard (only the higher left stride peak is caught sometimes)

    % has some trouble with jogging data where the R step peak is much
    % lower amplitude than while running, and not distinct enough to
    % separate the L+R cleanly like while walking

    % 1*std of acc data seems to catch both L+R steps while running though

    scatter(ts(segment_start + pkids - 1), acc_filt(segment_start + pkids - 1), 'ro'); hold on;

    fprintf("\nSteps/min for segment %.2fs to %.2fs = %.2f", ts(t-500), ts(t), cadence);
end

