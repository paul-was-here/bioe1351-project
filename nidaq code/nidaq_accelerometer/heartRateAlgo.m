x = load('saved_ppg_data.mat');
figure()

for i = 1:100:length(x.ppg_datasave(:,1))
    ts = x.ppg_datasave(i:i+99, 1);
    ppg = x.ppg_datasave(i:i+99, 2);

    waitforbuttonpress;
    cla;

    ts = ts-ts(1);
    
    yyaxis right;
    cla;
    plot(ts, ppg, 'b-'); hold on;
    yyaxis left;
    
    hr = getHeartrate(ts, ppg);
    
    disp(hr);
    
end




function hr = getHeartrate(ts, ppg)
    % Reject noise and calculate a heartrate threshold

    % Algorithm Settings:
    noise_rejection_threshold =         2;
    peak_detection_threshold =          1.5;
    
    % Filter operations:
    [b,a] = butter(3, 0.5/10, "high");
    filt = filtfilt(b,a,ppg);

    plot(ts, filt, 'k-');


    upper_lim = noise_rejection_threshold*std(filt);
    lower_lim = -1 * upper_lim;

    % Set ts to start at 0:
    ts = ts - ts(1);

    above_lim_idxs = find(filt > upper_lim);
    below_lim_idxs = find(filt < lower_lim);

    out_of_bounds_idxs = [above_lim_idxs; below_lim_idxs];
    disp(out_of_bounds_idxs)

    if isempty(out_of_bounds_idxs)
        % Case 1: No data is out of bounds
        [~, pkids] = findpeaks(filt, 'MinPeakProminence', ...
            peak_detection_threshold*std(filt));
        hr = 60/mean(diff(ts(pkids)));
        plot(ts, filt, 'r-', LineWidth = 2);
        yline(noise_rejection_threshold*std(filt), 'r');
        yline(-noise_rejection_threshold*std(filt), 'r')
        yline(peak_detection_threshold*std(filt), 'k--');
        yline(-peak_detection_threshold*std(filt), 'k--');
        return
    else
        left_noise_lim = min(out_of_bounds_idxs);
        right_noise_lim = max(out_of_bounds_idxs);

        if ts(left_noise_lim) > 3
            ts = ts(1:left_noise_lim-10);
            filt = filt(1:left_noise_lim-10);
        elseif ts(end) - ts(right_noise_lim) > 3
            ts = ts(right_noise_lim+10:end);
            filt = filt(right_noise_lim+10:end);
        elseif ts(right_noise_lim) - ts(left_noise_lim) > 4
            ts = ts(left_noise_lim+1:right_noise_lim-1);
            filt = filt(left_noise_lim+1:right_noise_lim-1);
        else
            hr = "No heart rate could be computed";
            return
        end
            [~, pkids] = findpeaks(filt, 'MinPeakProminence', ...
                peak_detection_threshold*std(filt));
            hr = 60/mean(diff(ts(pkids))); % printed outside of function

            % Try FFT method:
            Fs = length(filt)/(ts(end)-ts(1));
            fprintf("Fs: %.2f", Fs)
            N = length(ppg);
            Y = fft(ppg);
            P2 = abs(Y/N);
            P1 = P2(1:N/2+1);
            P1(2:end-1) = 2*P1(2:end-1);
            f = Fs*(0:(N/2))/N;
            
            mask = (f > 0.5 & f < 3);
            P1_filt = P1(mask);
            f_filt = f(mask);

            [~, max_idx] = max(P1_filt);
            dominantFreq = f_filt(max_idx);
            fft_hr = 60/dominantFreq;

            figure(2);
            plot(f_filt, P1_filt);

            figure(1);
                
            fprintf("\n HR (fft method): %.2f\n", fft_hr);


            plot(ts, filt, 'r-', LineWidth = 2)
            yline(noise_rejection_threshold*std(filt), 'r');
            yline(-noise_rejection_threshold*std(filt), 'r')
            yline(peak_detection_threshold*std(filt), 'k--');
            yline(-peak_detection_threshold*std(filt), 'k--');
            return
    end
end
