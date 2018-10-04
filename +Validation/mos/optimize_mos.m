% This script optimize mos metric over a fixed grid of register valus
% with respect to a recorded data (corresponding to that grid of values)

%% define grid of values (next time I should save this with the recorded data)
if exist(data,'var')
    [sort_bypass_mode, JFIL_sharpS_range, RAST_sharpS_range, ...
        RAST_sharpS_range, RAST_sharpR_range] = data.reg_values;      
else
    sort_bypass_mode = [0,4];
    JFIL_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
    JFIL_sharpR_range = [0,1,2,4,8,16,32,48,63];
    RAST_sharpS_range = [0,1,2,3,4,6,8,12,16,20,24,32,48,63];
    RAST_sharpR_range = [0,1,2,4,8,16,32,48,63];
end
dim_sizes = [length(sort_bypass_mode), length(JFIL_sharpS_range),...
             length(JFIL_sharpR_range), length(RAST_sharpS_range),...
             length(RAST_sharpR_range)];
tot_elm = prod(dim_sizes);

regs_indices = num2cell(1:5);
[sort_bypass_index, JFIL_sharpS_index, JFIL_sharpR_index,...
        RAST_sharpS_index, RAST_sharpR_index] = deal(regs_indices{:});

 
%% smooth data

% smooth data with gaussian kernel
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
padded_mos_scores1 = padarray(squeeze(mos_scores_nans_to_zeros(1,:,:,:,:)), [1 1 1 1], 'replicate', 'both');
padded_mos_scores2 = padarray(squeeze(mos_scores_nans_to_zeros(2,:,:,:,:)), [1 1 1 1], 'replicate', 'both');
smoothed_mos_scores1 = convn(padded_mos_scores1,(1/(3^4))*ones(3,3,3,3),'valid');
smoothed_mos_scores2 = convn(padded_mos_scores2,(1/(3^4))*ones(3,3,3,3),'valid');
smoothed_mos_scores = cat(5,smoothed_mos_scores1,smoothed_mos_scores2);
smoothed_mos_scores = permute(smoothed_mos_scores, [5,1,2,3,4]);

%% find local minimas
local_minimas_linear_ind = [];
neighborhood_size = [2 1 2 1];
sort_indices = 1:2;
for i=1:numel(smoothed_mos_scores)
    [sort_ind, JFIL_sharpS_ind, JFIL_sharpR_ind,...
        RAST_sharpS_ind, RAST_sharpR_ind] = ind2sub(dim_sizes,i);
    JFIL_sharpS_indices = max(1,JFIL_sharpS_ind-neighborhood_size(1)):...
        min(dim_sizes(2),JFIL_sharpS_ind+neighborhood_size(1));
    JFIL_sharpR_indices = max(1,JFIL_sharpR_ind-neighborhood_size(2)):...
        min(dim_sizes(3),JFIL_sharpR_ind+neighborhood_size(2));
    RAST_sharpS_indices = max(1,RAST_sharpS_ind-neighborhood_size(3)):...
        min(dim_sizes(4),RAST_sharpS_ind+neighborhood_size(3));
    RAST_sharpR_indices = max(1,RAST_sharpR_ind-neighborhood_size(4)):...
        min(dim_sizes(5),RAST_sharpR_ind+neighborhood_size(4));
    patch = smoothed_mos_scores(sort_indices, JFIL_sharpS_indices, ...
        JFIL_sharpR_indices, RAST_sharpS_indices, RAST_sharpR_indices);
    [~,I] = min(patch(:));
    
end