function [FRA, taso] = get_FRA(stimTable, spike_times, fra_bin)
%function [FRA, taso] = get_FRA(stimTable, spike_times, fra_bin)
%
% Parameters:
%   - fra_bin: 2-element vector for start and end of window to consider
%   average firing rate (e.g. [0, 0.15])


% Preassign frequency response area variables
stimTable = sortrows(stimTable, {'Frequency','dB_SPL','StartTime'});
[freqs, levels] = meshgrid( unique(stimTable.Frequency), unique(stimTable.dB_SPL));

% Ensure spike times is a row vector
if iscolumn(spike_times)
  spike_times = transpose(spike_times);
end           

% Get spike times after sound onset                                                          
taso = bsxfun(@minus, spike_times, stimTable.StartTime);
taso = transpose(taso);   

% Get spike rate across time
nhist = histc( taso, fra_bin);
nhist = nhist(1,:)' ./ diff(fra_bin);    

FRA = nan( size( freqs));

for stim_idx = 1 : numel(freqs)

  rows = ismember([stimTable.Frequency stimTable.dB_SPL],...
                [freqs(stim_idx) levels(stim_idx)],'rows');

  FRA(stim_idx) = mean(nhist(rows));
end

% Convert to table
column_names = cellfun(@num2str, num2cell(freqs(1,:)), 'un', false);
row_names = cellfun(@num2str, num2cell(levels(:,1)), 'un', false);
FRA = array2table(FRA, 'VariableNames', column_names, 'RowNames', row_names);
