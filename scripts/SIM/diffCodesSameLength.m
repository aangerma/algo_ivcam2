%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comparison over changing target reflectivity between propCode code 52,
% propCode code 26 with duplication of each symbol twice and revised barker
% code (1-->0, -1-->1) with duplication of each symbol by 4. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize variables:
num_of_codes = 3;
num_of_code_reps = 2;
codes = zeros(52, num_of_codes, 'logical');
codes(:,1) = Codes.propCode(52,1);
barkerish = logical([0 0 0 0 0 1 1 0 0 1 0 1 0]); %Barker code 1-->0, -1-->1
codes(:,2) = repelem(barkerish,4)'; % Repeat each symbol 4 times
codes(:,3) = repelem(Codes.propCode(26,1),2)'; % Repeat each symbol twice
statist_reps = 50;
reflectivity = 0.05:0.05:0.3;
orig_code_order = [52, 13, 26];
out_dir = 'D:\data\sim_data\diff_codes_same_length'; % Directory for saving the results
param_file_path = 'D:\data\simulatorParams\52_64 for compare\params_860SKU1_indoor_52_code.xml';
sim_data = xml2structWrapper(param_file_path); % Simulation parameters
sim_data.laser.codeLength = 52;
sim_data.runTime = (1+num_of_code_reps)*sim_data.laser.codeLength; %First code is not used
varNames = {'Code','OrigCode','Reflectivity','TargetDistance', 'TotalSTD','TotalMean','STD70mm','Mean70mm', 'Percent70mm', 'STD50mm','Mean50mm', 'Percent50mm','STD30mm','Mean30mm', 'Percent30mm'};
[varTypes{1:length(varNames)}] = deal('double');
tot_num_table_rows = length(reflectivity)*num_of_codes;
result_T = table('Size',[tot_num_table_rows length(varNames)], 'VariableTypes',varTypes,'VariableNames',varNames);
target_dist = sim_data.targetDist;
sim_dist_correct = 190; %[mm] simulation assumed delay
%----------------------------------------------------------------------------
% Run the test:
for i_ref = 1:length(reflectivity)
    sim_data.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    dist_arr = zeros(num_of_codes, statist_reps);
    for i_stat = 1:statist_reps
        for i_code = 1: num_of_codes           
            sim_data.laser.txSequence = codes(:,i_code);
            [dist_arr(i_code,i_stat)] = runSimAndcalcTargetDistance(sim_data);
        end
        disp(['Finished ' num2str(i_stat) '/' num2str(statist_reps) ' rounds']);
    end
    ix_table_shift = (i_ref-1)*num_of_codes;
    dist_arr = dist_arr - sim_dist_correct;
    for k1 = 1:num_of_codes
        dist_data = dist_arr(k1,:);
        [rng_STD_70, rng_mean_70, percent_in_rng_70] = get_STD_mean_within_range(dist_data, [target_dist - 70, target_dist + 70]);
        [rng_STD_50, rng_mean_50, percent_in_rng_50] = get_STD_mean_within_range(dist_data, [target_dist - 50, target_dist + 50]);
        [rng_STD_30, rng_mean_30, percent_in_rng_30] = get_STD_mean_within_range(dist_data, [target_dist - 30, target_dist + 30]);
        
        result_T(k1+ix_table_shift, :) = {52, orig_code_order(k1), reflectivity(i_ref), target_dist, std(dist_data), mean(dist_data),...
            rng_STD_70, rng_mean_70, percent_in_rng_70,...
            rng_STD_50, rng_mean_50, percent_in_rng_50,...
            rng_STD_30, rng_mean_30, percent_in_rng_30};
    end
    save([ out_dir '\reflect_' num2str(reflectivity(i_ref)) '.mat'], 'dist_arr', 'codes', 'orig_code_order', 'sim_data');
end
save([out_dir '\results\results_table.mat'], 'result_T');