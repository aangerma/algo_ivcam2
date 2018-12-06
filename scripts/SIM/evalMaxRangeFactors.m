function [] = evalMaxRangeFactors()

target_dist = 2000;
code_length = 52;
double_code_length = code_length*2;
comparator_freq = 8;
code_reps = 2; % The first code length is not used
half_code_reps = floor(code_reps/2) + 1; % The first code length is not used
compare_reps = 1;
targtDist1_arr = zeros(compare_reps,1);
targtDist2_arr = zeros(compare_reps,1);
%----------------------------------------------------------------------------------------------------------------------------------------
for k = 1:compare_reps
    % Short code
    time_smpl = struct('isTimeLength', false, 'value', code_reps); %[nSec] or number of code repetitions
    [targtDist1_arr(k)] = calcTargetDistance(target_dist,code_length, comparator_freq, time_smpl);
    
    % Double length code
    time_smpl.value = half_code_reps;
    [targtDist2_arr(k)] = calcTargetDistance(target_dist,double_code_length, comparator_freq, time_smpl);
    disp(['Finished ' num2str(k) '/' num2str(compare_reps) ' rounds']);
end
z1_std = std(targtDist1_arr);
z2_std = std(targtDist2_arr);

mean1 = mean(targtDist1_arr);
mean2 = mean(targtDist2_arr);

disp(['Target distance is: ' num2str(target_dist) '[mm], # of repetitions for each config = ' num2str(compare_reps)]);
disp(['Code length ' num2str(code_length) ' with ' num2str(code_reps-1) ' repetitions:']);
disp(['mean =  ' num2str(mean1) ' [mm] with STD = ' num2str(z1_std) ' [mm]']);
disp(['Code length ' num2str(double_code_length) ' with ' num2str(half_code_reps-1) ' repetitions:']);
disp(['mean =  ' num2str(mean2) ' [mm] with STD = ' num2str(z2_std) ' [mm]']);

end



