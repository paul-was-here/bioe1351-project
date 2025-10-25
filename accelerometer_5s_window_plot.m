%{
Author: Paul Kullmann
BIOENG 1351/2351 Project
%}

device = serialport("/dev/cu.usbmodem101",115200);
configureTerminator(device, "LF");
flush(device);

ts = [];
acc = [];
starttime = datetime("now");
fs = 100;

figure();

while true
    if device.NumBytesAvailable > 0
        line = readline(device);
        data = str2double(split(line, ','));
        readtime = datetime("now");

        

        try
            x_data = data(1,:)*3.3/1024-1.5;
            y_data = data(2,:)*3.3/1024-1.5;
            acc = [acc, (sqrt(x_data^2+y_data^2))];
            ts = [ts, seconds(readtime-starttime)];

            plot(ts, acc, 'k-');

            xlim([ts(end-5*fs), ts(end)])
            ylim([-1.5 1.5])


            drawnow limitrate;
        
        catch
            display('error getting data');
        end

        if length(ts) == fs*6
            ts = ts(101:600);
            acc = acc(101:600);
            

        end
        %display(length(ts))
    end
end


