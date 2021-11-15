# Matlab

## Simple Demo
To generate and plot a frequency-response area for a single electrode/unit:


```
% Load stimulus info and spike times
stimTable = readtable('stimulus_metadata.csv');
spike_times = readmatrix('RecA_C13_spike_times.txt');

% Generate FRA and plot
[FRA, ~] = get_FRA(stimTable, spike_times, [0, 0.15]);
plot_FRA(FRA);
```
