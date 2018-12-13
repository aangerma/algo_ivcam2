function [] = dispAndSaveDistCompare(targtDist1_arr, targtDist2_arr, sim_data1, sim_data2, out_dir, file_name)
z1_std = std(targtDist1_arr);
z2_std = std(targtDist2_arr);

mean1 = mean(targtDist1_arr);
mean2 = mean(targtDist2_arr);

disp(['Target distance is: ' num2str(sim_data1.targetDist) '[mm], # of repetitions for each config = ' num2str(length(targtDist1_arr))]);
disp(['Code length ' num2str(sim_data1.laser.codeLength) ' with ' num2str(sim_data1.runTime/sim_data1.laser.codeLength-1) ' repetitions:']);
disp(['mean =  ' num2str(mean1) ' [mm] with STD = ' num2str(z1_std) ' [mm]']);
disp(['Code length ' num2str(sim_data2.laser.codeLength) ' with ' num2str(sim_data2.runTime/sim_data2.laser.codeLength-1) ' repetitions:']);
disp(['mean =  ' num2str(mean2) ' [mm] with STD = ' num2str(z2_std) ' [mm]']);

if nargin() == 6
    save([ out_dir '\' file_name '.mat'], 'targtDist1_arr', 'sim_data1', 'targtDist2_arr', 'sim_data2');
end
end

