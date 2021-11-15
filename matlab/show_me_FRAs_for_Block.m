function show_me_FRAs(stimTable, spikeTimes, time_opts, plot_opts)
%
%
% INPUTS
%   - stimTable: Table with columns for tone onset time ('startTime'), frequency ('frequency') and level ('level') 
%   - spikeTimes: Vector of spike times for one unit
%   - time_opts [optional]: Struct containing timing options
%   - plot_opts [optional]: Struct containing plotting options, will not plot if empty
%
% Dependencies:
%   - align_event_times.m
%   - show_me_the_spikes.m
%   - dealSubplots.m
%   - drawRaster.m
%   - plotSE_patch.m
%   - myPrint.m
%
% Version History:
% ----------------
% Created on 13 December 2019 by Stephen Town
% Branched on 01 Feb 2020 
% Modified 30 May 2020 - added data / figure saving
%  2021-11-15: Branched from show_me_FRAs_for_Block.m
%



try
   
    % Parse inputs
    if ~exist('time_opt','var')
      time_opt = struct('fra_bin_width',0.15, 'psth_bin_width',0.1, 'psth_window',[-0.1, 0.2], 'responsive_window', 0.1);
    end
    
    if ~exist('plot_opt','var')
      plot_opt = struct();
    end
   
  
                  
    options = struct('tlim', [0 inf], 'cleaning', 'none', 'fS', 2e4,...
        'draw', struct('waveform', true, 'times', false));
              
    % Define time vectors    
    psth_bins = time_opt.psth_window(0) : time_opt.psth_bin_width : time_opt.psth_window(1);
    resp_bins = -time_opt.responsive_window : time_opt.responsive_window : time_opt.responsive_window;        
    raster_bins = time_opt.psth_window(0) : 0.001 : time_opt.psth_window(1);
    fra_bin = [0 time_opt.fra_bin_width];
                  
    
    
    
    % Get stimulus onsets in neural file (and save)
    matched_times = align_event_times(block_path); 
    stim.CorrectedStartTime = transpose( matched_times);   
    stim( isnan( stim.CorrectedStartTime), :) = [];     % Remove uncertain stimulus times
    writetable( stim, fullfile( save_path, strrep( txt_file.name, '.txt', '.csv')))
    
    stim = sortrows(stim, {'Frequency','dB_SPL','StartTime'});
    options.tlim(2) = max(stim.CorrectedStartTime) + (max(psth_bins) * 1.5);
    
    % Preassign frequency response area variables
    [freqs, levels] = meshgrid( unique(stim.Frequency), unique(stim.dB_SPL));
    
    % For each h5 file containing neural data
    for i = 1 : numel(h5_files)
        
        % Load neural data
        h5_path = fullfile( block_path, h5_files(i).name);
        [spike_times, chan_map, wv, vStats, opt] = show_me_the_spikes( h5_path, options);
        
        spike_times = cellfun(@transpose, spike_times, 'un', 0);      
        nChans = numel( spike_times);  
        wv = struct('mean', cellfun(@mean, wv, 'un', 0),...
                    'std', cellfun(@std, wv, 'un', 0));
        
        % Save spike times and signal stats
        spike_file = strrep( h5_files(i).name, '.h5', '_spiketimes.mat');
        save( fullfile( save_path, spike_file), 'spike_times','wv','chan_map','vStats','opt','matched_times')

        stats_file = strrep( spike_file, 'spiketimes.mat','vStats.csv');
        writetable( vStats, fullfile( save_path, stats_file), 'delimiter', ',')       
        
        % Draw and save PSTH
        fig = figure( 'name', ['PSTH: ' h5_files(i).name],...
                    'position', [50 50 1850 950]);
        sp = dealSubplots(4, nChans/4);       

        good_chans = nan( nChans, 1);
            
        for chan = 1 : nChans                                                            

            taso = bsxfun(@minus, spike_times{chan}, stim.CorrectedStartTime);
            taso = transpose(taso);                                

            nhist = histc( taso, psth_bins);
            nhist = nhist ./ bin_width;

            good_chans(chan) = is_responsive( taso, resp_bins);
            if good_chans(chan) == 1
                color = 'k';
            else
                color = grey;
            end

            chan_idx = chan_map.MCS_Chan == chan;
            axes( sp( chan_map.Subplot_idx( chan_idx)))

            plotSE_patch( psth_bins, nhist', 'x', gca, color);

            xlabel('Time (s)')
            ylabel('Firing Rate (Hz)')        

            warp_chan = chan_map.Warp_Chan( chan_idx);
            title(sprintf('E%02d: C%02d', warp_chan, chan))
        end    

        fig_file = strrep( h5_files(i).name, '.h5', '_psth');
        myPrint( fullfile( save_path, fig_file), 'png', 150)
        close(fig)
        
        % Draw and save Raster
        fig = figure( 'name', ['Raster: ' h5_files(i).name],...
                    'position', [50 50 1850 950]);
        sp = dealSubplots(4, nChans/4);       
                    
        for chan = 1 : nChans                                                            

            taso = bsxfun(@minus, spike_times{chan}, stim.CorrectedStartTime);
            nhist = histc( transpose(taso), raster_bins);

            chan_idx = chan_map.MCS_Chan == chan;
            ax = sp( chan_map.Subplot_idx( chan_idx));

            drawRaster( nhist', raster_bins, ax, stim.Frequency, cmocean('thermal'))
  
            warp_chan = chan_map.Warp_Chan( chan_idx);
            title(sprintf('E%02d: C%02d', warp_chan, chan))
        end    

        fig_file = strrep( h5_files(i).name, '.h5', '_raster');
        myPrint( fullfile( save_path, fig_file), 'png', 150)
        close(fig)
        
        % Draw and save FRA
        fig =  figure( 'name', ['FRA: ' h5_files(i).name],...
                'position', [50 50 1850 950]);     
        sp = dealSubplots(4, nChans/4); 

        for chan = 1 : nChans

            taso = bsxfun(@minus, spike_times{chan}, stim.CorrectedStartTime);
            nhist = histc( transpose(taso), fra_bin);
            nhist = nhist(1,:)' ./ diff(fra_bin);    

            spike_rate = nan( size( freqs));

            for stim_idx = 1 : numel(freqs)

                rows = ismember([stim.Frequency stim.dB_SPL],...
                                [freqs(stim_idx) levels(stim_idx)],'rows');

                spike_rate(stim_idx) = mean(nhist(rows));
            end

            chan_idx = chan_map.MCS_Chan == chan;
            axes( sp( chan_map.Subplot_idx( chan_idx)))  

            imagesc( freqs(1,:) ./ 1e3, levels(:,1), spike_rate) 

            xlabel('Frequency (kHz)')
            ylabel('Level (dB SPL)')

            warp_chan = chan_map.Warp_Chan( chan_idx);
            title(sprintf('E%02d: C%02d', warp_chan, chan))

            axis tight

            % Remove outliers when setting color scale
            good_rates = ~isoutlier( spike_rate(:), 'Threshold', 5);
            good_rates = spike_rate( good_rates);
            
            if any(good_rates > 0)
                set(gca,'CLim',minmax(good_rates'))
            end
            
            if good_chans(chan) == 1
                colormap(gca,magma);
            else
                colormap(gca,'gray');
            end
            
        end
        
        fig_file = strrep( h5_files(i).name, '.h5', '_FRA');
        myPrint( fullfile( save_path, fig_file), 'png', 150)
        close(fig)        
    end

    
catch err
    err
    keyboard
end


function is_good = is_responsive( taso, resp_bins)

% Get difference in number of spikes before and after tone
nhist = histc( taso, resp_bins);
x = diff(nhist(1:2,:));
is_good = ttest(x);

