good_form_data = load("good form acc.mat");
bad_form_data = load("bad form acc.mat");

ts_good = good_form_data.acceler_datasave(:,1);
ts_bad = bad_form_data.acceler_datasave(:,1);

y_good = good_form_data.acceler_datasave(:,3);
y_bad = bad_form_data.acceler_datasave(:,3);

fs = 300;

[b,a] = butter(3, 15/fs/2, "low");
[c,d] = butter(3, 1/fs/2, "high");

y_good_filt = filtfilt(b,a,y_good);
y_bad_filt = filtfilt(b,a,y_bad);

%y_good_filt = filtfilt(c,d,y_good_filt1);
%y_bad_filt = filtfilt(c,d,y_bad_filt1);

figure()
plot(ts_good, y_good_filt,'r-');
yyaxis right;
plot(ts_bad, y_bad_filt, 'k-');
legend("Good Form", "Bad Form");

good_window_ts = ts_good(10*fs:30*fs,:);
good_window_y = y_good_filt(10*fs:30*fs,:);
bad_window_ts = ts_bad(10*fs:30*fs,:);
bad_window_y = y_bad_filt(10*fs:30*fs,:);


x_good = good_window_y; 
L_good = length(x_good);          % Number of samples
Y_good = fft(x_good);             % FFT
P2_good = abs(Y_good / L_good);   % Two-sided spectrum
P1_good = P2_good(1:L_good/2+1);  % One-sided spectrum
P1_good(2:end-1) = 2 * P1_good(2:end-1);
f_good = fs * (0:(L_good/2)) / L_good;

x_bad = bad_window_y;
L_bad = length(x_bad);
Y_bad = fft(x_bad);
P2_bad = abs(Y_bad / L_bad);
P1_bad = P2_bad(1:L_bad/2+1);
P1_bad(2:end-1) = 2 * P1_bad(2:end-1);
f_bad = fs * (0:(L_bad/2)) / L_bad;

%P1_good = P1_good/max(P1_good);
%P1_bad = P1_bad/max(P1_bad);

figure(2);
plot(f_good, P1_good, 'k-', LineWidth=1.5); hold on;
plot(f_bad, P1_bad, 'r-', LineWidth=1.5)
legend("Good Form", "Bad Form");
ylabel("FFT")
xlabel("Frequency (Hz)")
xlim([0.3 5]);