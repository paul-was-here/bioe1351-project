%{
Author: Paul Kullmann
Modified: 10/23/25

Purpose: Read and plot data saved from the serial reading of connected
Arduino + accelerometer for preliminary project testing.
Use Arduino_Accelerometer.py to read & save from serial port.
%}

filename = '~/desktop/acc_data.csv';
%filename = '~/desktop/SpeedUpSlowDown.csv';

data = load(filename);
data(:,2) = data(:,2)*3.3/1024-3.3/2;
data(:,3) = data(:,3)*3.3/1024-3.3/2;

figure();
hold on;
%plot(data(:,1), data(:,2),'k-',DisplayName="X Data")
plot(data(:,1), data(:,3),'b-',DisplayName="Y Data")

% zero-phase low-pass
fs = 9600; %assume sampling rate = baud rate 9600
wn = 100/(fs/2); % Sets cutoff frequency for filter
[b,a] = butter(1,wn,'low'); % Creates butterworth filter
filtered = filtfilt(b,a,data(:,3)); % Performs filter operation

%filtered = bandpass(data(:,3),[1 25],fs);

%plot(data(:,1), filtered)

legend("X Data","Y Data")
xlabel("Time (s)")
ylabel("Voltage (V)")
title(filename)