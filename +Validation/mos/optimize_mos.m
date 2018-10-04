% This script optimize mos metric over a fixed grid of register valus
% with respect to a recorded data (corresponding to that grid of values)

%% define grid of values
if exist('data','var')
%     [sort_bypass_mode, JFIL_sharpS_range, RAST_sharpS_range, ...
%         RAST_sharpS_range, RAST_sharpR_range] = data.reg_values;
    dim_sizes = size(data.frames);
else
    sort_bypass_mode = [0,4];
    JFIL_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
    JFIL_sharpR_range = [0,1,2,4,8,16,32,48,63];
    RAST_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
    RAST_sharpR_range = [0,1,2,4,8,16,32,48,63];
    dim_sizes = [length(sort_bypass_mode), length(JFIL_sharpS_range),...
             length(JFIL_sharpR_range), length(RAST_sharpS_range),...
             length(RAST_sharpR_range)];
end
dim_sizes = size(mos_scores);
tot_elm = prod(dim_sizes);

regs_indices = num2cell(1:5);
[sort_bypass_index, JFIL_sharpS_index, JFIL_sharpR_index,...
        RAST_sharpS_index, RAST_sharpR_index] = deal(regs_indices{:});

 
%% smooth data with gaussian kernel

% mu = zeros(1,4);
% Sigma = diag(0.25*ones(4,1));
% x1 = linspace(-3,3,13);
% x2 = linspace(-3,3,9); 
% x3 = linspace(-3,3,13);
% x4 = linspace(-3,3,9);
% [X1,X2,X3,X4] = ndgrid(x1,x2,x3,x4);
% ker = mvnpdf([X1(:),X2(:),X3(:),X4(:)],mu,Sigma);
% ker = reshape(ker,length(x1),length(x2),length(x3),length(x4));
% mos_scores_nans_to_zeros = mos_scores;
% mos_scores_nans_to_zeros(isnan(mos_scores_nans_to_zeros)) = 0;
% padded_mos_scores1 = padarray(squeeze(mos_scores_nans_to_zeros(1,:,:,:,:)), [6 4 6 4], 'replicate', 'both');
% padded_mos_scores2 = padarray(squeeze(mos_scores_nans_to_zeros(2,:,:,:,:)), [6 4 6 4], 'replicate', 'both');
% smoothed_mos_scores1 = convn(padded_mos_scores1,ker,'valid');
% smoothed_mos_scores2 = convn(padded_mos_scores2,ker,'valid');
% smoothed_mos_scores = cat(5,smoothed_mos_scores1,smoothed_mos_scores2);
% smoothed_mos_scores = permute(smoothed_mos_scores, [5,1,2,3,4]);

%% smooth data by averaging neighborhoods

max_val = max(mos_scores(:));
mos_scores_nans_to_zeros = mos_scores;
mos_scores_nans_to_zeros(isnan(mos_scores_nans_to_zeros)) = 2*max_val;
% separate data with respect to the sort_bypass_mode dimension
% and average them separately and then concatenate them again
padded_mos_scores1 = padarray(squeeze(mos_scores_nans_to_zeros(1,:,:,:,:)), ...
    [1 1 1 1], 'replicate', 'both');
padded_mos_scores2 = padarray(squeeze(mos_scores_nans_to_zeros(2,:,:,:,:)), ...
    [1 1 1 1], 'replicate', 'both');
ker = ones(3,3,3,3);
smoothed_mos_scores1 = convn(padded_mos_scores1,(1/numel(ker))*ker,'valid');
smoothed_mos_scores2 = convn(padded_mos_scores2,(1/numel(ker))*ker,'valid');
smoothed_mos_scores = cat(5,smoothed_mos_scores1,smoothed_mos_scores2);
smoothed_mos_scores = permute(smoothed_mos_scores, [5,1,2,3,4]);

%% find global minimas

num_of_min = 5; 
neighborhood_size = [2 1 2 1];
sort_indices = 1:2;
remaining_min = num_of_min;
while remaining_min>0
    [M,I] = min(smoothed_mos_scores(:));
    remaining_min = remaining_min - 1;
    best_configurations(num_of_min - remaining_min).mos_score = M;
    [sort_ind, JFIL_sharpS_ind, JFIL_sharpR_ind, ...
            RAST_sharpS_ind, RAST_sharpR_ind] = ind2sub(dim_sizes,I);
    if exist('data','var')
        sort_bypass_val = data.reg_values.sort_bypass_mode(sort_ind);
        JFIL_sharpS_val = data.reg_values.JFIL_sharpS_range(JFIL_sharpS_ind);
        JFIL_sharpR_val = data.reg_values.JFIL_sharpR_range(JFIL_sharpR_ind);
        RAST_sharpS_val = data.reg_values.RAST_sharpS_range(RAST_sharpS_ind);
        RAST_sharpR_val = data.reg_values.RAST_sharpR_range(RAST_sharpR_ind);
    else
        sort_bypass_val = sort_bypass_mode(sort_ind);
        JFIL_sharpS_val = JFIL_sharpS_range(JFIL_sharpS_ind);
        JFIL_sharpR_val = JFIL_sharpR_range(JFIL_sharpR_ind);
        RAST_sharpS_val = RAST_sharpS_range(RAST_sharpS_ind);
        RAST_sharpR_val = RAST_sharpR_range(RAST_sharpR_ind);
    end
    best_configurations(num_of_min - remaining_min).configuration = create_params_struct(sort_bypass_val, ...
        JFIL_sharpS_val, JFIL_sharpR_val, RAST_sharpS_val, RAST_sharpR_val);
    JFIL_sharpS_indices = max(1,JFIL_sharpS_ind-neighborhood_size(1)):...
        min(dim_sizes(2),JFIL_sharpS_ind+neighborhood_size(1));
    JFIL_sharpR_indices = max(1,JFIL_sharpR_ind-neighborhood_size(2)):...
        min(dim_sizes(3),JFIL_sharpR_ind+neighborhood_size(2));
    RAST_sharpS_indices = max(1,RAST_sharpS_ind-neighborhood_size(3)):...
        min(dim_sizes(4),RAST_sharpS_ind+neighborhood_size(3));
    RAST_sharpR_indices = max(1,RAST_sharpR_ind-neighborhood_size(4)):...
        min(dim_sizes(5),RAST_sharpR_ind+neighborhood_size(4));
    smoothed_mos_scores(sort_ind, JFIL_sharpS_indices, JFIL_sharpR_indices, ...
        RAST_sharpS_indices, RAST_sharpR_indices) = inf;
end

%% save best configurations
best_configurations_path = 'X:\Users\dor\MOS optimization\mos_data_27_09\best_mos_configurations.mat';
save(best_configurations_path, 'best_configurations');
