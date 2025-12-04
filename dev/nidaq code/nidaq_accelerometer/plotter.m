data = load("saved_ppg_data.mat");
ts = data.ppg_datasave(:,1);
ppg = data.ppg_datasave(:,2);

[b,a] = butter(3,.5/25,"high");

figure()
ts_window = ts(end-99:end);
ppg_window = ppg(end-99:end);

filt = filtfilt(b,a,ppg_window);

plot(ts_window, filt); hold on;

thres = 1*std(filt);
[pks, pkids] = findpeaks(filt, "MinPeakProminence", thres);
hr = 60/mean(diff(ts_window(pkids)));
fprintf("\nheart rate: %f", hr)
plot(ts_window(pkids), pks, 'ro')


%plot(ts(end-99:end), ppg(end-99:end))

%{
for i = 1:25:length(ppg)
    plot(ts(i:i+24), ppg(i:i+24))
    waitforbuttonpress;
end
%}