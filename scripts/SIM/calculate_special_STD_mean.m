path = 'D:\data\sim_data\half_code_double_length';
dir_data = dir(path);
sim_dist_correct = 190;
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
    true_dist = sim_data_code1.targetDist;
    if true_dist ~= sim_data_code2.targetDist
        error('The target distance is different between files compared!');
        
    end
    [dist_within_800_STD1, dist_within_800_mean1, percent_in_800_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 800, true_dist + 800]);
    [dist_within_700_STD1, dist_within_700_mean1, percent_in_700_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 700, true_dist + 700]);
    [dist_within_600_STD1, dist_within_600_mean1, percent_in_600_rng1] = get_STD_mean_within_range(targtDist1_arr, [true_dist - 600, true_dist + 600]);
    
    [dist_within_800_STD2, dist_within_800_mean2, percent_in_800_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 800, true_dist + 800]);
    [dist_within_700_STD2, dist_within_700_mean2, percent_in_700_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 700, true_dist + 700]);
    [dist_within_600_STD2, dist_within_600_mean2, percent_in_600_rng2] = get_STD_mean_within_range(targtDist2_arr, [true_dist - 600, true_dist + 600]);
    
    disp(['Target distance: ' num2str(true_dist) '[mm]. Target reflectivity: ' num2str(sim_data_code1.environment.wavelengthReflectivityFactor)]);
    disp(['Code length: ' num2str(sim_data_code1.laser.codeLength) ', # repetitions: ' num2str(sim_data_code1.runTime/sim_data_code1.laser.codeLength -1)]);
    disp(['Percent within 80 [cm] = ' num2str(percent_in_800_rng1) ', Percent within 70 [cm] = '  num2str(percent_in_700_rng1) ', Percent within 60 [cm] = '  num2str(percent_in_600_rng1)]);
    disp(['Code length: ' num2str(sim_data_code2.laser.codeLength) ', # repetitions: ' num2str(sim_data_code2.runTime/sim_data_code2.laser.codeLength -1)]);
    disp(['Percent within 80 [cm] = ' num2str(percent_in_800_rng2) ', Percent within 70 [cm] = '  num2str(percent_in_700_rng2) ', Percent within 60 [cm] = '  num2str(percent_in_600_rng2)]);
end

function [rng_STD, rng_mean, percent_in_rng] = get_STD_mean_within_range(orig_arr, rang)
new_dist_arr = orig_arr(orig_arr > rang(1) & orig_arr < rang(2));
rng_STD = std(new_dist_arr);
rng_mean = mean(new_dist_arr);

percent_in_rng = 100*length(new_dist_arr)/length(orig_arr);
end