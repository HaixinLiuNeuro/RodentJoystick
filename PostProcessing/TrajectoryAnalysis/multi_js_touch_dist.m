function [set_distances, set_distances_strings] = multi_js_touch_dist(dirlist,varargin)
%multi_js_touch_dist(dirlist,[targ_reward, dist_thresh, targ_time, combineflag, ax])
%generates distance distributions and js_touch_dist for multiple days
default = {0.25, 50, 300, 0, []};
numvarargs = length(varargin);
if numvarargs > 5
    error('too many arguments (> 6), only 1 required and 5 optional.');
end
[default{1:numvarargs}] = varargin{:};
[targ_reward, dist_thresh, targ_time, combineflag, ax] = default{:};
if length(ax)<1;
    figure;
    ax = gca();
end
[statslist, dates] = load_stats(dirlist, combineflag);
colors = 'rgbkmcyrgbkmcyrgbkmcy';
set_distances = zeros(1, length(statslist));
for i= 1:length(statslist)
    [set_dist] = js_touch_dist(statslist(i),targ_time,targ_reward,dist_thresh, 0, ax, colors(i));
    set_distances(i) = set_dist;
end
axes(ax);
legend(dates);
for i = 1:length(statslist);
    set_distances_strings{i} = [dates{i},': ', num2str(set_distances(i))];
end 

end

