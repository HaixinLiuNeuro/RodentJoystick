%xy_getstats(jstruct, index) returns a struct containing several fields
%describing an entire day's (folder's) trajectories.
function jstruct_stats = xy_getstats(jstruct,varargin)
default = {[0 inf]};
numvarargs = length(varargin);
if numvarargs > 1
    error('too many arguments (> 2), only one required and one optional.');
end
[default{1:numvarargs}] = varargin{:};
[index] = default{:};

%Count the Number of nosepokes, JS (onsets and offsets), JS_post (onsets and offsets)
%and Number of Pellets dispensed
np_count=0; js_r_count = 0; js_l_count = 0; pellet_count = 0;
for i=1:length(jstruct)
    np_count = np_count + size(jstruct(i).np_pairs,1);
    js_r_count = js_r_count + size(jstruct(i).js_pairs_r,1);
    js_l_count = js_l_count + size(jstruct(i).js_pairs_l,1);
    pellet_count = pellet_count + numel(jstruct(i).reward_onset);
end
jstruct_stats.np_count = np_count;
jstruct_stats.js_r_count = js_r_count;
jstruct_stats.js_l_count = js_l_count;
jstruct_stats.pellet_count = pellet_count;
    
% Get Distribution of NP_JS
list=[];
for i=1:length(jstruct)
    if (numel(jstruct(i).np_pairs)>0 && numel(jstruct(i).js_pairs_r>0))
        for j=1:size(jstruct(i).np_pairs,1)
            %keep adding each 
            list = [list;(jstruct(i).js_pairs_r(:,1)-jstruct(i).np_pairs(j,1))];
        end
    end
end
jstruct_stats.np_js = list(find((list>-10000)&(list<10000)));

% Get Distribution of NP_JSPost
list=[];
for i=1:length(jstruct)
    if (numel(jstruct(i).np_pairs)>0 && numel(jstruct(i).js_pairs_l>0))
        for j=1:size(jstruct(i).np_pairs,1)
            list = [list;(jstruct(i).js_pairs_l(:,1)-jstruct(i).np_pairs(j,1))];
        end
    end
end
jstruct_stats.np_js_post = list(find((list>-10000)&(list<10000)));

%5 Get PDF of trajectories
traj_struct = [];
traj_pdf_jstrial= zeros(100,100);
k=0;

trialnum=0; 
for struct_index=1:length(jstruct)
    %% initialize   
    traj_x = jstruct(struct_index).traj_x;
    traj_y = jstruct(struct_index).traj_y;
    np_pairs = jstruct(struct_index).np_pairs;
    rw_onset = jstruct(struct_index).reward_onset;
    js_pairs_r = jstruct(struct_index).js_pairs_r;
    js_pairs_l = jstruct(struct_index).js_pairs_l;
    js_reward = jstruct(struct_index).js_reward;
    
    try
        laser_on = jstruct(struct_index).laser_on;        
    end
    
    %% Process, and develop traj_struct
    start_temp =0;
    onset_ind = 1;
    if numel(js_pairs_r)>0 && numel(np_pairs)>0 && numel(js_pairs_l)>0
        for j=1:size(js_pairs_r,1)
            if(sum(((np_pairs(:,1)-js_pairs_r(j,1))<0)&((np_pairs(:,2)-js_pairs_r(j,1))>0))>0) 
            % If the Joystick is in between an nosepoke onset and a nosepoke offset pair
            if (sum(((js_pairs_l(:,1)-js_pairs_r(j,1))<0)&((js_pairs_l(:,2)-js_pairs_r(j,1))>0))>0) 
                % And if the Joystick is in between an post-touch onset and offset pair
                % This is now a valid trial
                    
                %FIND NP ONSET/OFFSET
                np_js_temp = (np_pairs(:,1)-js_pairs_r(j,1))<0; 
                %set of nose poke onsets preceding the js onset
                start_p = max(np_pairs(np_js_temp,1));
                %Nose poke before the Joystick touch is the most recent
                %touch (largest time) out of all preceding np ons
                np_end = np_pairs((np_pairs(np_js_temp,1)==start_p),2); 
                %corresponding nose poke offset
                    
                %FIND TRIAL NUMBER
                %count as new trial only if prev joystick attempt
                %wasn't on the same nosepoke onset offset
                if (start_p ~= start_temp)                   
                    trialnum = trialnum+1;
                end
                start_temp = start_p;
                    
                %FIND CORRESPONDING POST ONSET/OFFSET
                %set of post touch onsets preceding the js onset
                jt_js_temp = (js_pairs_l(:,1)-js_pairs_r(j,1))<0; 
                % Post-touch onset
                post_start =  max(js_pairs_l(jt_js_temp,1)); 
                % Post-touch offset
                post_end = js_pairs_l((js_pairs_l(jt_js_temp,1)==post_start),2);
                %End of trajectory is min of nosepoke ending,joystick
                %touch offset,or reward offset if a rewarded trial whichever comes first
                stop_p = min([js_pairs_r(j,2),np_end,post_end]); 

                if js_reward(j)
                rw_or_stop = min([js_pairs_r(j,2),np_end,post_end,rw_onset(onset_ind)])-js_pairs_r(j,1); 
                else
                rw_or_stop = min([js_pairs_r(j,2),np_end,post_end]) - js_pairs_r(j,1); 
                end              
                
                %If optogenetic expt was on, determine if "Hit" trial or
                %"Catch" trial
                try
                if sum(((laser_on(:,1))>js_pairs_r(j,1))&((laser_on(:,1))<js_pairs_r(j,2)))>0
                    laser = 1;
                else
                    laser = 0;
                end
                catch
                    laser = 0;
                end
                
                traj_x_t = traj_x(js_pairs_r(j,1):stop_p);
                traj_y_t = traj_y(js_pairs_r(j,1):stop_p);
                mag_traj = ((traj_x_t.^2+traj_y_t.^2).^(0.5));
                %make sure nose poke occurs at point where joystick mag <50
                if ((traj_x(start_p)^2+traj_y(start_p)^2)^(0.5))<50
                    k=k+1;
                    
                    
                    traj_struct(k).traj_x = traj_x_t;
                    traj_struct(k).traj_y = traj_y_t;
                    traj_struct(k).magtraj = mag_traj;
                    traj_struct(k).js_onset = js_pairs_r(j,1);
                    traj_struct(k).start_p = start_p;
                    traj_struct(k).stop_p = stop_p;
                    traj_struct(k).rw = js_reward(j);
                    traj_struct(k).rw_onset = 0;
                    traj_struct(k).laser = laser;
                    if traj_struct(k).rw == 1
                        traj_struct(k).rw_onset = rw_onset(onset_ind)-js_pairs_r(j,1);
                        onset_ind = onset_ind + 1;                        
                    end
                    traj_struct(k).magatnp = ((traj_x(start_p)^2+traj_y(start_p)^2)^(0.5));
                    traj_struct(k).max_value_ind = find(mag_traj==max(mag_traj));
                    traj_struct(k).max_value = max(mag_traj);
                    traj_struct(k).posttouch = stop_p-js_pairs_r(j,1);
                    traj_struct(k).rw_or_stop = rw_or_stop;
                    traj_pdf_jstrial = traj_pdf_jstrial + hist2d([traj_y_t',traj_x_t'],-100:2:100,-100:2:100);
                end
            end    
            end  
        end
    end
end



jstruct_stats.traj_pdf_jstrial = traj_pdf_jstrial./sum(sum(traj_pdf_jstrial));
jstruct_stats.numtraj = k;
jstruct_stats.traj_struct = traj_struct;
jstruct_stats.trialnum = trialnum;
jstruct_stats.srate = jstruct_stats.pellet_count/trialnum;
% Get Theta Distributions