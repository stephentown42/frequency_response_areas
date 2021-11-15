function FRA_demo()
% function FRA_demo()
%
% Draws a frequency-response area for an example unit with known frequency tuning

% Load stimulus info and spike times
stimTable = readtable('stimulus_metadata.csv');
spike_times = readmatrix('RecA_C13_spike_times.txt');

% Generate FRA and plot
[FRA, ~] = get_FRA(stimTable, spike_times, [0, 0.15]);
plot_FRA(FRA);
