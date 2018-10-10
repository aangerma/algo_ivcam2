%% load recorded data

mos_data_folder_path = 'D:\Data\Ivcam2\mos\mos_data_09_27';
if ~exist(mos_data_folder_path,'dir')
    error('folder of mos data does not exist');
end
mos_data_path = [mos_data_folder_path,'\mos_data.mat'];
if ~exist(mos_data_path,'file')
    error('mos_data.mat file does not exist');
end
% note: the next line loads the recorded data and can take over 10 minutes
load(mos_data_path);

%% compute mos score for each configuration and store the scores in a multidimensional array

% initialize the data structure that holds the 
% mos scores for each configuration
reg_values = data.reg_values;
dim_sizes = [length(reg_values.sort_bypass_mode), ...
    length(reg_values.JFIL_sharpS_range), length(reg_values.JFIL_sharpR_range), ...
    length(reg_values.RAST_sharpS_range), length(reg_values.RAST_sharpR_range)];
mos_scores = zeros(size(data.frames));
params = Validation.aux.defaultMetricsParams();
params.camera.K = data.K;
params.verbose = true;

for ind = 1:numel(data.frames)
    if mod(ind,50) == 0
        fprintf('starting iteration number: %d\n',ind);
    end
    mos_scores(ind) = Validation.metrics.mos(data.frames{ind}.frame,params);
end

%% save mos scores
mos_scores_path = mos_data_folder_path;
save([mos_scores_path '\mos_scores.mat'], 'mos_scores');
