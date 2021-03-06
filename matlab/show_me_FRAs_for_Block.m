function show_me_FRAs(stimTable, spikeTimes, time_opts, plot_opts)
%
%
% INPUTS
%   - stimTable: Table with columns for tone onset time ('startTime'), frequency ('Frequency') and level ('dB_SPL') 
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
      return_opt = struct('FRA_plot',true,'FRA_text',true,'PSTH_plot',true,'Raster_plot',true);
    end
   
    % Define time vectors    
    psth_bins = time_opt.psth_window(0) : time_opt.psth_bin_width : time_opt.psth_window(1);
    resp_bins = -time_opt.responsive_window : time_opt.responsive_window : time_opt.responsive_window;        
    raster_bins = time_opt.psth_window(0) : 0.001 : time_opt.psth_window(1);
    fra_bin = [0 time_opt.fra_bin_width];
                             
    % Get Frequency Repsonse Area    
    FRA, taso = get_FRA(stimTable, spike_times, fra_bin)
    
    
    % Test if unit is responsive across all tones
    [h, p] = is_responsive( taso, resp_bins);
    if h
      fprintf('Unit is responsive to tones (p = %.3f)', p)
    else
      fprintf('Unit did not respond to tones (p = %.3f)', p)
    end
      
    % Plotting options
    if return_opt.PSTH_plot
      psth_fig = draw_PSTH(taso, psth_bins)
    end
    
    if retrun_opt.Raster_plot
      raster_fig = draw_raster_wrapper(taso, raster_bins)
    end
      
    if return_opt.FRA_plot
      FRA_fig = draw_FRA
    end   

function fig = draw_FRA(taso)

fig = figure();     
     


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
    

    
catch err
    err
    keyboard
end


function FRA, taso = get_FRA(stim, spike_times, fra_bin)

   % Preassign frequency response area variables
   stimTable = sortrows(stimTable, {'Frequency','dB_SPL','StartTime'});
   [freqs, levels] = meshgrid( unique(stimTable.Frequency), unique(stimTable.dB_SPL));
 
   % Ensure spike times is a row vector
   if iscolumn(spike_times)
      spike_times = transpose(spike_times)
   end           

   % Get spike times after sound onset                                                          
   taso = bsxfun(@minus, spike_times, stimTable.startTime);
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
   FRA = array2table(FRA, 'VariableNames', num2str(unique(stimTable.Frequency)), 'RowNames', num2str(unique(stimTable.dB_SPL)))


function h, p = is_responsive( taso, resp_bins)
% function is_good = is_responsive( taso, resp_bins)
% 
% Get difference in number of spikes before and after tone
   nhist = histc( taso, resp_bins);
   x = diff(nhist(1:2,:));
   h, p = ttest(x);


function fig = draw_PSTH(taso, psth_bins)
% function fig = draw_PSTH(taso, psth_bins)
%
% Draw PSTH
   nhist = histc( taso, psth_bins);
   nhist = nhist ./ bin_width;

   fig = figure();

   plotSE_patch( psth_bins, nhist', 'x', gca, color);

   xlabel('Time (s)')
   ylabel('Firing Rate (Hz)')    
   
   
% Draw Raster
function fig = draw_raster_wrapper(taso, raster_bins, stimTable)

   fig = figure();

   nhist = histc( taso, raster_bins);

   drawRaster( nhist', raster_bins, ax, stimTable.Frequency, cmocean('thermal'))
