function fra = get_FRA(stimTimes, ev_times, frequencies, levels)
% function fra = get_FRAM(stimTimes, ev_times, stimParams)
%
% Parameters:
% -----------
%   - stimTimes: n-by-1 vector containing the times of tone onset
%   - ev_times: p-by-1 vector containing the times of spikes for one unit / neuron
%   - freqeuncies: n-by-1 matrix containing the frequencies of tones
%   - levels: n-by-1 matrix containing the levels of tones
%
% Returns:
% -------
%   - fra: u-by-v matrix showing the mean firing rate of the unit for each combination of frequency and attenuation

% Settings
time_window = 0.1;

% Get unique frequencies and levels
unique_freqs = unique(frequencies);
n_freqs = length(unique_freqs);

unique_levels = unique(levels);
n_levels = length(unique_levels);

% Preassign
fra = zeros(n_levels, nfreqs);
bin_edges = [0 : time_window : time_window];

% For each combination of tone frequency and level
for i = 1 : n_freqs,
    for j = 1 : n_levels,
              
        % Select all stimuli with combination of frequency and level
        rows = frequencies == unique_freqs(i) && levels == unique_levels(j);
        
        % Get spike times relative to stimulus onset
        tone_onsets = stimTimes(rows);
        taso = bsxfun(@minus, ev_times, onset;   
        
        spike_count = zeros(size(stimTimes2));
        
        for k = 1 : length(stimTimes2),
           
            onset = stimTimes2(k);
             

            temp = histc(taso, bin_edges);            
            n(k) = temp(1) ;            
        end
        
        fra(j,i) = mean(n)./ 0.1;
        
        fprintf('%.1f Hz, %d dB = %d Spikes per sec\n', freqs(i), attns(j), fra(j,i))
    end
end
