function [set_distances, set_distances_strings] = multi_js_touch_dist(dirlist,varargin)
%[set_dist, set_dist_str] = multi_js_touch_dist(dirlist,[interv, ...
%   targ_reward, dist_thresh, targ_time, combineflag, plotflag, ax])
%
%   runs analysis script js_touch_dist on all entries in dirlist with the
%   (optional) parameters specified
%
% OUTPUTS
%
%   set_dist :: vector of distances (double array) corresponding to each
%       directory in dirlist, each day represented in dirlist, or the
%       entire list's data (see combineflag)
%
%   set_dist_str :: cell array version of set_dist (same information)
%
% ARGUMENTS
%
%   dirlist :: standard struct  representation of a list of directories
%       from rdir
%
%   interv :: histogram plotting interval (ms)
%       DEFAULT - 20
%generates distance distributions and js_touch_dist for multiple days
default = {20, 0.25, 50, 300, 0, 1, 1, [], 0};
numvarargs = length(varargin);
if numvarargs > 9
    error('too many arguments (> 10), only 1 required and 9 optional.');
end
[default{1:numvarargs}] = varargin{:};
[interv, targ_reward, dist_thresh, targ_time, combineflag, plotflag, smoothparam, ax, traj_id] = default{:};
if plotflag && isempty(ax);
    figure;
    ax = gca();
end
%% Temporary
traj_id=1;
%%

[statslist, dates] = load_stats(dirlist, combineflag, 'traj_struct');
colors = 'rgbkmcyrgbkmcyrgbkmcy';
set_distances = zeros(1, length(statslist));

if (traj_id == 1)
 for stat_index=1:length(statslist)
     tstruct = statslist(stat_index).traj_struct;
     output = arrayfun(@(y) ~isempty(find(y.laser == 1)), tstruct);
     tstruct = tstruct(output);
     statslist(stat_index).traj_struct=tstruct;
 end
elseif (traj_id==2)
 for stat_index=1:length(statslist)
     tstruct = statslist(stat_index).traj_struct;
     output = arrayfun(@(y) ~isempty(find(y.laser == 0)), tstruct);
     tstruct = tstruct(output);
     statslist(stat_index).traj_struct=tstruct;
 end
else 
 % do nothing, all trajectories go into computation
end

alltraj = 1;
for i= 1:length(statslist)
    [set_dist] = js_touch_dist(statslist(i), interv, targ_time, ...
        targ_reward,dist_thresh, alltraj, plotflag, smoothparam, ax, colors(i));
    set_distances(i) = set_dist;
end
if plotflag
    axes(ax);
    legend(dates);
end
for i = 1:length(statslist);
    set_distances_strings{i} = [dates{i},': ', num2str(set_distances(i))];
end 

end

