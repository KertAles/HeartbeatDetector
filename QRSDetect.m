function [idxs] = QRSDetect(fileName)
%%
% use WFDB Toolbox for MATLAB and Octave from
% https://www.physionet.org/physiotools/matlab/wfdb-app-matlab/
% First, ADD PATH in Matlab enviroment where your data are stored (100.dat, 100.hea, 100.atr)
% use function rdsamp() to read samples
% [signal,Fs,tm]=rdsamp(recordName,signaList,N,N0,rawUnits,highResolution)
% file = '100';
%fs = 360;
[signal, fs, time] = rdsamp(fileName);
% to read annotation use function rdann()
% [ann,anntype,subtype,chan,num,comments]=rdann(recordName, annotator, C, N, N0, AT)
%[ann, anntype, subtype, chan, num, comments] = rdann(append('mit-bih/', file),'atr');

%ann(1) = [];

ECG_raw = signal(:, 1);

data_length = length(signal);

%% 
% baseline extraction

Fc = 2.5;
T = 1/fs;
ECG = HPFilter(ECG_raw, Fc, T);


%% 
% Haar-like filtering
B_1 = floor(0.025 * fs);
B_2 = floor(0.06 * fs);
c = (2*(B_2-B_1))/(2*B_1 + 1);

filter = zeros(B_2 * 2 + 1, 1) - 1;
filter((B_2 + 1 - B_1):(B_2+1+B_1)) = c;

filtered_ecg = conv(ECG, filter, 'same');

%%
% Calculating 2nd derivative

der_fil = [-1 2 -1];

ecg_scnd_der = conv(ECG, der_fil, 'same');

%%
% calculating scoring function & getting candidates
c_1 = 0.55;

scoring_fun = filtered_ecg .* (ECG + c_1 .* ecg_scnd_der);

offset = floor(0.2 * fs);

peak_candidates = [];

for k = 1:length(filtered_ecg)
    from_idx = max(k-offset, 1);
    to_idx = min(k+offset, data_length);
    
    score_k = abs(scoring_fun(k));
    
    is_loc_max = true;
    for n = from_idx:to_idx
        if n ~= k
            score_n = abs(scoring_fun(n));
            
            if score_n >= score_k
                is_loc_max = false;
            end
        end
    end
    
    if is_loc_max
       peak_candidates = cat(1, peak_candidates, k);
    end
end


%%

% Adaptive thresholding

T = 0.75;
tau = [0.45, 0.25, 0.15, 0.1, 0.05];

beta_1 = 0.4;
beta_2 = 2.9;

filtered_peaks = [];
filtered_times = [];

%length(peak_candidates)
for i = 1:length(peak_candidates)
    %W_1 calc
    scores_timeframe = abs(scoring_fun(max(1, peak_candidates(i)-fs * 10):peak_candidates(i)));
    scores_timeframe = sortrows(scores_timeframe, 1, 'descend');
    
    if length(scores_timeframe) >= 5
        S_5 = scores_timeframe(5);
        W_1 = T + S_5;
    else
        S_5 = scores_timeframe(length(scores_timeframe));
        W_1 = T + S_5;
    end
    
    %W_2 calc
    detects = length(filtered_peaks);
    
    abs_dist_thing = 0;
    
    if detects > 4
            last_few = min(detects, 5);
            last_few_det = filtered_peaks(end-last_few+1:end);

            if detects > 5
                diffs = [];
                for j = 1:(last_few-1)
                    diff = last_few_det(j) - last_few_det(j+1);
                    diffs = cat(1, diffs, diff);
                end
                avg_diff = mean(diffs);

                diff_fst = last_few_det(end) - last_few_det(end-1);
                if diff_fst < 0.7 * avg_diff
                    last_few = min(detects , 6);
                    last_few_det = filtered_peaks(end-last_few+1:end-1);
                end
            end
           
            
            %I_e = tau(1) * (peak_candidates(i) - last_few_det(end));
            I_e = 0;
            for j = 1:(length(last_few_det)-1)
                I_e = I_e + tau(j) * (last_few_det(end-j+1) - last_few_det(end-j));
            end
        
        dist_thing = (peak_candidates(i) - filtered_peaks(end)) / I_e;
        abs_dist_thing = abs(dist_thing - round(dist_thing));
    end
    
    W_2 = beta_1 + beta_2 * abs_dist_thing;
    
    adapt_threshold = W_1 * W_2;
    
    if abs(scoring_fun(peak_candidates(i))) > adapt_threshold
        filtered_peaks = cat(1, filtered_peaks, peak_candidates(i));
        filtered_times = cat(1, filtered_times, time(peak_candidates(i)));
    end
end

%%
% variation ratio test

offset_var = round(fs*0.1);
filtered_var_peaks = [];
filtered_var_times = [];

for i = 1:length(filtered_peaks)
    from = max(1, filtered_peaks(i) - offset_var);
    to = min(data_length, filtered_peaks(i) + offset_var);
    
    u_1 = max(ECG(from:to)) - min(ECG(from:to));
    
    u_2 = 0;
    for j = from+1:to
        u_2 = u_2 + abs(ECG(j) - ECG(j-1));
    end
    
    omega = u_1 / u_2;
    
    if abs(omega - 0.5) <= 0.275
        filtered_var_peaks = cat(1, filtered_var_peaks, filtered_peaks(i));
        filtered_var_times = cat(1, filtered_var_times, filtered_times(i));
    end
end

idxs = filtered_var_peaks;
end
