%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comparison over changing target reflectivity between propCode code 26,
% 52,74 and 104 and repetitions of code 52 1, 2, 3 amd 4 times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize variables:
code_len_arr = [26, 52, 74, 104];
code_reps = 2:4;
statist_reps = 50;
reflectivity = 0.05:0.05:0.3;
out_dir = 'D:\data\sim_data\length_reps'; % Directory for saving the results
param_file_path = 'D:\data\simulatorParams\52_64 for compare\params_860SKU1_indoor_52_code.xml';
sim_data = xml2structWrapper(param_file_path); % Simulation parameters
varNames = {'Code','Repetitions','Reflectivity','TargetDistance', 'TotalSTD','TotalMean','STD70mm','Mean70mm', 'Percent70mm', 'STD50mm','Mean50mm', 'Percent50mm','STD30mm','Mean30mm', 'Percent30mm'};
[varTypes{1:length(varNames)}] = deal('double');
tot_num_table_rows = length(reflectivity)*(length(code_len_arr)+length(code_reps));
result_T = table('Size',[tot_num_table_rows length(varNames)], 'VariableTypes',varTypes,'VariableNames',varNames);
target_dist = sim_data.targetDist;
sim_dist_correct = 190; %[mm] simulation assumed delay
%----------------------------------------------------------------------------
% Run the test:
for i_ref = 1:length(reflectivity)
    sim_data.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    dist_arr = zeros(length(code_len_arr)+length(code_reps), statist_reps);
    for i_stat = 1:statist_reps
        for i_len = 1: length(code_len_arr)
            sim_data.laser.codeLength = code_len_arr(i_len);
            sim_data.runTime = 2*sim_data.laser.codeLength; %First code is not used
            sim_data.laser.txSequence = Codes.propCode(sim_data.laser.codeLength,1);
            [dist_arr(i_len,i_stat)] = runSimAndcalcTargetDistance(sim_data);
        end
        for i_reps = 1:length(code_reps)
            sim_data.laser.codeLength = code_len_arr(1);
            sim_data.runTime = (1+code_reps(i_reps))*sim_data.laser.codeLength; %First code is not used
            sim_data.laser.txSequence = Codes.propCode(sim_data.laser.codeLength,1);
            [dist_arr(i_len+i_reps,i_stat)] = runSimAndcalcTargetDistance(sim_data);
        end
        disp(['Finished ' num2str(i_stat) '/' num2str(statist_reps) ' rounds']);
    end
    ix_table_shift = (i_ref-1)*(length(code_len_arr)+length(code_reps));
    dist_arr = dist_arr - sim_dist_correct;
    for k1 = 1:length(code_len_arr)
        dist_data = dist_arr(k1,:);
        [rng_STD_70, rng_mean_70, percent_in_rng_70] = get_STD_mean_within_range(dist_data, [target_dist - 70, target_dist + 70]);
        [rng_STD_50, rng_mean_50, percent_in_rng_50] = get_STD_mean_within_range(dist_data, [target_dist - 50, target_dist + 50]);
        [rng_STD_30, rng_mean_30, percent_in_rng_30] = get_STD_mean_within_range(dist_data, [target_dist - 30, target_dist + 30]);
        
        result_T(k1+ix_table_shift, :) = {code_len_arr(k1), 1, reflectivity(i_ref), target_dist, std(dist_data), mean(dist_data),...
            rng_STD_70, rng_mean_70, percent_in_rng_70,...
            rng_STD_50, rng_mean_50, percent_in_rng_50,...
            rng_STD_30, rng_mean_30, percent_in_rng_30};
    end
    for k2 = 1:length(code_reps)
        dist_data = dist_arr(k1+k2,:);
        [rng_STD_70, rng_mean_70, percent_in_rng_70] = get_STD_mean_within_range(dist_data, [target_dist - 70, target_dist + 70]);
        [rng_STD_50, rng_mean_50, percent_in_rng_50] = get_STD_mean_within_range(dist_data, [target_dist - 50, target_dist + 50]);
        [rng_STD_30, rng_mean_30, percent_in_rng_30] = get_STD_mean_within_range(dist_data, [target_dist - 30, target_dist + 30]);
        
        result_T(k1+k2+ix_table_shift, :) = {code_len_arr(1), code_reps(k2), reflectivity(i_ref), target_dist, std(dist_data), mean(dist_data),...
            rng_STD_70, rng_mean_70, percent_in_rng_70,...
            rng_STD_50, rng_mean_50, percent_in_rng_50,...
            rng_STD_30, rng_mean_30, percent_in_rng_30};
    end 
    save([ out_dir '\reflect_' num2str(reflectivity(i_ref)) '.mat'], 'dist_arr', 'code_len_arr', 'code_reps', 'sim_data');
end
save([out_dir '\results\results_table.mat'], 'result_T');


%----------------------------------------------------------------------------
% Helper function:
