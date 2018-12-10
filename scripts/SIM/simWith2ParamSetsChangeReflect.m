function [targtDist1_arr, targtDist2_arr] = simWith2ParamSetsChangeReflect(reflectivity, compare_reps, paramFile1, paramFile2, outDir)
% paramFile1 = 'D:\data\simulatorParams\half_code_double_reps\params_860SKU1_indoor_half_code.xml';
% paramFile2 = 'D:\data\simulatorParams\half_code_double_reps\params_860SKU1_indoor_double_code.xml';
visdiff(paramFile1, paramFile2, 'xml')
uiwait(msgbox('Please verify the difference between files', 'Attention'));

sim_data_code1 = xml2structWrapper(paramFile1); % Simulation parameters
sim_data_code1.laser.txSequence = Codes.propCode(sim_data_code1.laser.codeLength,1);

sim_data_code2 = xml2structWrapper(paramFile2); % Simulation parameters
sim_data_code2.laser.txSequence = Codes.propCode(sim_data_code2.laser.codeLength,1);

for i_ref = 1:length(reflectivity)
    targtDist1_arr = zeros(compare_reps,1);
    targtDist2_arr = zeros(compare_reps,1);
    %----------------------------------------------------------------------------------------------------------------------------------------
    sim_data_code1.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    sim_data_code2.environment.wavelengthReflectivityFactor = reflectivity(i_ref);   
    
    for k = 1:compare_reps
        [targtDist1_arr(k)] = calcTargetDistance(sim_data_code1);
        
        [targtDist2_arr(k)] = calcTargetDistance(sim_data_code2);
        disp(['Finished ' num2str(k) '/' num2str(compare_reps) ' rounds']);
    end
    z1_std = std(targtDist1_arr);
    z2_std = std(targtDist2_arr);
    
    mean1 = mean(targtDist1_arr);
    mean2 = mean(targtDist2_arr);
    
    disp(['Target distance is: ' num2str(sim_data_code1.targetDist) '[mm], # of repetitions for each config = ' num2str(compare_reps) ', Reflectivity = ' num2str(reflectivity(i_ref))]);
    disp(['Code length ' num2str(sim_data_code1.laser.codeLength) ' with ' num2str(sim_data_code1.runTime/sim_data_code1.laser.codeLength-1) ' repetitions:']);
    disp(['mean =  ' num2str(mean1) ' [mm] with STD = ' num2str(z1_std) ' [mm]']);
    disp(['Code length ' num2str(sim_data_code2.laser.codeLength) ' with ' num2str(sim_data_code2.runTime/sim_data_code2.laser.codeLength-1) ' repetitions:']);
    disp(['mean =  ' num2str(mean2) ' [mm] with STD = ' num2str(z2_std) ' [mm]']);
    if nargin() == 5
        save([ outDir '\reflect_' num2str(reflectivity(i_ref)) '.mat'], 'targtDist1_arr', 'sim_data_code1', 'targtDist2_arr', 'sim_data_code2');
    end
end
end



