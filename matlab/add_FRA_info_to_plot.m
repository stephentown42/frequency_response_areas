function add_FRA_info_to_plot(FRA_info, plot_opts, ax)
% function add_FRA_info_to_plot(FRA_info, plot_opts, ax)

if nargin < 2
    plot_opts = struct('bounds',true, 'CF', true, 'Q10', true, 'Q30', true);
    ax = gca;
end

% Make sure you're adding to figure
set(ax,'nextplot','add')

if plot_opts.bounds
    plot(FRA_info.boundary.Frequency, FRA_info.boundary.Level, '--k'); 
end

if plot_opts.CF
    y = get(ax,'ylim');
    x = repmat(FRA_info.characteristic_frequency, 2, 1);
    plot(x,y,'k')
end

if plot_opts.Q10
    y = min(FRA_info.boundary.Level) + 5;    
    plot(FRA_info.Q10, [y y], 'k', 'marker','*')
end


if plot_opts.Q30
    y = nanmean(FRA_info.boundary.Level)+5;    
    plot(FRA_info.Q30, [y y], '-k', 'marker','o')
end


