% path = 'D:\data\sim_data\half_code_double_length';
path = 'D:\data\sim_data\52_64 compare\2_repetitions';
dir_data = dir(path);
sim_dist_correct = 190;
num_diff_runs = 0;
for k = 1:length(dir_data)
    if dir_data(k).isdir
        continue;
    end
    num_diff_runs = num_diff_runs + 1;
end
verbose = false;
[varTypes{1:13}] = deal('double');
varNames = {'Code','Reflectivity','TotalSTD','TotalMean','STD70mm','Mean70mm', 'Percent70mm', 'STD50mm','Mean50mm', 'Percent50mm','STD30mm','Mean30mm', 'Percent30mm'};
result_T = table('Size',[num_diff_runs 13], 'VariableTypes',varTypes,'VariableNames',varNames);
table_count = 1;
for k = 1:length(dir_data)
    if dir_data(k).isdir
        continue;
    end
    load([path '\' dir_data(k).name]);
    
    targtDist1_arr = targtDist1_arr - sim_dist_correct;
    targtDist2_arr = targtDist2_arr - sim_dist_correct;
    total_STD1 = std(targtDist1_arr);
    total_mean1 = mean(targtDist1_arr);
    total_STD2 = std(targtDist2_arr);
    total_mean2 = mean(targtDist2_arr);
    true_dist = sim_data1.targetDist;
    if true_dist ~= sim_data2.targetDist
        error('The target distance is different between files compared!');
        
    end
    [dist_within_70_STD1, dist_within_70_mean1, percent_in_70_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 70, true_dist + 70]);
    [dist_within_50_STD1, dist_within_50_mean1, percent_in_50_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 50, true_dist + 50]);
    [dist_within_30_STD1, dist_within_30_mean1, percent_in_30_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 30, true_dist + 30]);
    
    [dist_within_70_STD2, dist_within_70_mean2, percent_in_70_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 70, true_dist + 70]);
    [dist_within_50_STD2, dist_within_50_mean2, percent_in_50_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 50, true_dist + 50]);
    [dist_within_30_STD2, dist_within_30_mean2, percent_in_30_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 30, true_dist + 30]);
    
    result_T(table_count,:) = {sim_data1.laser.codeLength, sim_data1.environment.wavelengthReflectivityFactor, total_STD1,...
        total_mean1, dist_within_70_STD1, dist_within_70_mean1, percent_in_70_rng1, dist_within_50_STD1, dist_within_50_mean1,...
        percent_in_50_rng1, dist_within_30_STD1, dist_within_30_mean1, percent_in_30_rng1};
    result_T(table_count+1,:) = {sim_data2.laser.codeLength, sim_data2.environment.wavelengthReflectivityFactor, total_STD2,...
        total_mean2, dist_within_70_STD2, dist_within_70_mean2, percent_in_70_rng2, dist_within_50_STD2, dist_within_50_mean2,...
        percent_in_50_rng2, dist_within_30_STD2, dist_within_30_mean2, percent_in_30_rng2};
    table_count = table_count + 2;
    
    if verbose
        disp(['Target distance: ' num2str(true_dist) '[mm]. Target reflectivity: ' num2str(sim_data1.environment.wavelengthReflectivityFactor)]);
        disp(['Code length: ' num2str(sim_data1.laser.codeLength) ', # repetitions: ' num2str(sim_data1.runTime/sim_data1.laser.codeLength -1)]);
        disp(['Percent within 70 [mm] = ' num2str(percent_in_70_rng1) ', Percent within 50 [mm] = '  num2str(percent_in_50_rng1) ', Percent within 30 [mm] = '  num2str(percent_in_30_rng1)]);
        disp(['Code length: ' num2str(sim_data2.laser.codeLength) ', # repetitions: ' num2str(sim_data2.runTime/sim_data2.laser.codeLength -1)]);
        disp(['Percent within 70 [mm] = ' num2str(percent_in_70_rng2) ', Percent within 50 [mm] = '  num2str(percent_in_50_rng2) ', Percent within 30 [mm] = '  num2str(percent_in_30_rng2)]);
    end
    
    save([path '\results\results_table.mat'], 'result_T');
end

function [rng_STD, rng_mean, percent_in_rng] = get_STD_mean_within_range(orig_arr, rang)
new_dist_arr = orig_arr(orig_arr > rang(1) & orig_arr < rang(2));
rng_STD = std(new_dist_arr);
rng_mean = mean(new_dist_arr);

percent_in_rng = 100*length(new_dist_arr)/length(orig_arr);
end