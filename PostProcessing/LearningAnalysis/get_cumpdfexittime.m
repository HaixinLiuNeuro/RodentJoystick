function [tau] = get_cumpdfexittime(stats,varargin)

default= {30,60,0};

numvarargs = length(varargin);
if numvarargs > 3
    error('too many arguments (> 4), only 1 required and 3 optional.');
end
[default{1:numvarargs}] = varargin{:};

[dist1,dist2,pdfSwitch] = default{:};

stats = get_stats_with_len(stats,50);
stats_reach = get_stats_with_reach(stats,dist2*(6.35/100));

stats_l = get_stats_with_trajid(stats_reach,1);
stats_nl = get_stats_with_trajid(stats_reach,2);

if pdfSwitch
    edges = 0:10:500;
    ylimmax = 0.1;
else
    edges = 0:1:500;
    ylimmax = 1;
end


if numel(stats_nl.traj_struct)>0
    [~,tau,~,ax] = tau_theta(stats_nl,dist1*(6.35/100),dist2*(6.35/100));
    tau_dist = histc(tau,edges);
    tau_dist = tau_dist/(sum(tau_dist));
    if pdfSwitch
        tau_cumdist = tau_dist;
    else
        tau_cumdist = cumsum(tau_dist);
    end
    h = figure;
    stairs(edges,tau_cumdist,'b');
    ylim([0 ylimmax]);
end

if numel(stats_l.traj_struct)>0
    [~,tau,~,ax] = tau_theta(stats_l,dist1*(6.35/100),dist2*(6.35/100),0,0,ax,1, 'r');
    tau_dist = histc(tau,edges);
    tau_dist = tau_dist/(sum(tau_dist));
    if pdfSwitch
        tau_cumdist = tau_dist;
    else
        tau_cumdist = cumsum(tau_dist);
    end
    figure(h)
    hold on
    stairs(edges,tau_cumdist,'r');
    hold off;
    ylim([0 ylimmax]);
end

