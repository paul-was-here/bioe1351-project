%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
%}

device = serialport("/dev/cu.usbmodem1101",115200);
configureTerminator(device, "LF");
flush(device);

ts = [];
acc = [];
cads = [];
starttime = datetime("now");
fs = 100;
pkinfo = [];
datasave = [];

% Butterworth low-pass this signal (2nd order, fc=5Hz)
[b,a] = butter(3, 4/(fs/2));

figure();

while true
    if device.NumBytesAvailable > 0
        line = readline(device);
        data = str2double(split(line, ','));
        readtime = datetime("now");

        

        try
            x_read = data(1,:);
            x_data = (x_read * 5/1024 - 3/2)/0.42;
            y_read = data(2,:);
            y_data = (y_read * 5/1024 -3/2) / 0.42;

            acc = [acc, (sqrt(x_data^2 + y_data^2))];
            ts = [ts, seconds(readtime-starttime)];

            time_save = seconds(readtime-starttime);
            acc_save = (sqrt(x_data^2 + y_data^2));

            datasave = [datasave; time_save, acc_save];
            if size(datasave,1) >= 180*fs
                save('Saved_Data.mat','datasave');
            end


            acc_filt = filtfilt(b, a, acc);

            plot(ts, acc_filt, 'k-', LineWidth=1); hold on;

            xlim([ts(end-5*fs), ts(end)])
            ylim([-1 5])

            drawnow limitrate;
        
        catch
            display('error getting data');
        end

        if length(ts) == fs*6
            ts = ts(101:600);
            acc = acc(101:600);
            acc_filt = acc_filt(101:600);

            thres = 2*std(acc_filt);
            %[pks, pkids] = findpeaks(acc_filt, 'MinPeakProminence', thres, 'MinPeakDistance', 15);
            [~, pkids] = findpeaks(acc_filt, 'MinPeakProminence', thres);

            cadence = 60/mean(diff(ts(pkids)));
            %fprintf("\ncadence = %f", cadence)

            % The cadence formula seems kind of flawed. I averaged 3
            % measurements which seems more accurate. I think we should do
            % a validation study with someone counting steps/min and
            % compare against calculated. Could also average for longer and
            % it might be more accurate
            % (one cadence measurement every 15/30/60s for exmaple)
            % it also stops working at slower speeds where the peak
            % amplitudes are really small

            cads = [cads, cadence];
            if length(cads) == 3
                new_cad = mean(cads);
                fprintf("\nCadence (steps/min): %.2f", new_cad);
                cads = [];
            end

            save("data.mat","acc_filt")

            cla;
            plot(ts, acc);
        end
        %display(length(ts))
    end
end


