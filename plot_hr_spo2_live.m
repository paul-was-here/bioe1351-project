%{
Author: Paul Kullmann
BIOENG 1351/2351 Project

Purpose: Live plot Red & IR PPG & SpO2 from connected Arduino board. Need
to perform peak detection to determine heartrate (included .h library is
unreliable).
%}

% Connect to serial port:
device = serialport("/dev/cu.usbmodem101",115200);
configureTerminator(device, "LF");
flush(device);

% Create figure:
figure(); hold on;
grid on;
xlabel("Time (s)")
ylabel("Value")

% Preallocate arrays:
red = [];
ir = [];
spo2 = [];
ts = [];
starttime = datetime("now");

% Main loop:
while true
    if device.NumBytesAvailable > 0
        line = readline(device);
        data = str2double(split(line, ','));
        readtime = datetime("now");

        try
            red = [red, data(1)];
            ir = [ir, data(2)];
            spo2 = [spo2, data(3)];
            ts = [ts, seconds(readtime-starttime)];
            fprintf("\n%f",spo2(end))

            if length(red) > 100
                yyaxis left;
                cla;
                yyaxis right;
                cla;
                red = [];
                ir = [];
                spo2 = [];
                ts = [];
            end

            yyaxis left
            plot(ts, red, 'r');
            ylim('tight');
            ylabel('Red')
            
            yyaxis right
            plot(ts, ir, 'b');
            ylim('tight');
            ylabel('IR')
            
            drawnow limitrate;
        catch
            fprintf('error plotting')
        end
    end
end