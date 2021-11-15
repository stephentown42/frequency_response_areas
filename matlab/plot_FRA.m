function fig = plot_FRA(FRA)
%function fig = plot_FRA(FRA)

    fig = figure();     
    hold on

    x = cellfun(@str2double, FRA.Properties.VariableNames);
    y = cellfun(@str2double, FRA.Row);    

    surface( x, y, FRA.Variables, 'edgecolor','none')     
    xlabel('Frequency (Hz)')
    ylabel('Level (dB SPL)')

    set(gca,'xscale','log')
    axis tight
    cbar = colorbar;
    ylabel(cbar, 'Spikes / s')
end

