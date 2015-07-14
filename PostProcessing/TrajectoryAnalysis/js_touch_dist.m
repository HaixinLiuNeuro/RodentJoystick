% js_touch_dist(stats,targ_time,targ_reward,dist_thresh, all_traj_flag) takes the stats
% structure, a target hold time, a target reward percentage, and a distance
% threshold and computes a recommended distribution threshold.
% ARGUMENTS: 
%   stats :: data structure generated by xy_getstats
%   targ_time :: target hold time in milliseconds
%   targ_reward :: target reward decimal representing the percentage of
%       which trials should be rewarded
%   dist_thresh :: the contingency used for the mice training
%   all_traj_flag :: if all_traj_flag == 1, function looks at all valid
%       trajectories within the nosepoke - otherwise, function only
%       examines the trajectory with the longest hold time.
% OUTPUT:
%   dist - the recommended threshold for the distance
%   
function [set_dist, med_time] = js_touch_dist(stats, varargin)
default = {300, 0.25, 50, 0, [], 'r'};
numvarargs = length(varargin);
if numvarargs > 6
    error('too many arguments (> 7), only 1 required and 6 optional.');
end
[default{1:numvarargs}] = varargin{:};
[targ_time, targ_reward, dist_thresh, all_traj_flag, ax, color] = default{:};
if length(ax)<1;
    figure;
    ax = gca();
end

traj_struct=stats.traj_struct;
start_prev=0;

holdlength=[];
for i=1:length(traj_struct)
    if (traj_struct(i).start_p == start_prev) && (all_traj_flag==0)
        holdlentemp = getmaxcontlength(traj_struct(i).magtraj,dist_thresh);
        if holdlentemp>holdlength(end)
            holdlength(end) = holdlentemp;
        end
    else 
        holdlength(end+1) = getmaxcontlength(traj_struct(i).magtraj,dist_thresh);
    end
    start_prev = traj_struct(i).start_p;
end

k=0;
holdlength_prev=0;
for i=1:length(traj_struct)
    
    if traj_struct(i).start_p == start_prev
        holdlentemp = getmaxcontlength(traj_struct(i).magtraj,150);
        if holdlentemp>holdlength_prev
            holdlength_prev = holdlentemp;
            if traj_struct(i).posttouch>targ_time
                dist_distri(k) = max(traj_struct(i).magtraj(1:targ_time));
            else
                dist_distri(k) = 0;
            end
        end
    else
        k=k+1;
        holdlength_prev = getmaxcontlength(traj_struct(i).magtraj,150);
        if traj_struct(i).posttouch>targ_time
            dist_distri(k) = max(traj_struct(i).magtraj(1:targ_time));
        else
            dist_distri(k) = 0;
        end
    end
    start_prev = traj_struct(i).start_p;
end

dist_distri=dist_distri(dist_distri>0);
dist_time_hld = 0:20:600;
holddist_vect = histc(holdlength,dist_time_hld);
axes(ax);
hold on;
stairs(dist_time_hld, holddist_vect./(sum(holddist_vect)),color,'LineWidth',2);
xlabel('Hold Time');
ylabel('Proportion');
title('JS Touch Hold Time Distr');
hold off;

time_success = length(dist_distri)/k;
c = histc(dist_distri,1:1:100);
success_prob = cumsum(c)/sum(c);
med_time = median(holdlength);
targ_dist = find(success_prob>(targ_reward/time_success));
if numel(targ_dist)>0
    set_dist = targ_dist(1);
else
    set_dist = 100;
end