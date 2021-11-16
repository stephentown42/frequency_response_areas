function spontaneous_rate = get_spontaneous_rate(stimTable, spike_times, time_window)
% function spontaneous_rate = get_spontaneous_rate(stimTable, spike_times, time_window)
%
% Gets the firing rate of the unit in a fixed time window (presumably
% just before the stimulus presentation when estimating the 'spontaneous'
% activity - though this is the users decision)
%
% Parameters:
%   - time window: 2-element vector for start and end of window to consider
%   average firing rate (e.g. [-0.15, 0])


% Ensure spike times is a row vector
if iscolumn(spike_times)
  spike_times = transpose(spike_times);
end           

% Get spike times after sound onset                                                          
taso = bsxfun(@minus, spike_times, stimTable.StartTime);
taso = transpose(taso);   

% Get spike rate across time
nhist = histc( taso, time_window);
nhist = nhist(1,:)' ./ diff(time_window);    

spontaneous_rate = mean(nhist);
