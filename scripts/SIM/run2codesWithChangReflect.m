function [targtDist1_arr, targtDist2_arr] = run2codesWithChangReflect(reflectivity, compare_reps, paramFile1, paramFile2, out_dir, file_name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs:
% reflectivity - an array of different reflectivity values for the
% simulation
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% paramFile1 = 'D:\data\simulatorParams\half_code_double_reps\params_860SKU1_indoor_half_code.xml';
% paramFile2 = 'D:\data\simulatorParams\half_code_double_reps\params_860SKU1_indoor_double_code.xml';
visdiff(paramFile1, paramFile2, 'xml')
uiwait(msgbox('Please verify the difference between files', 'Attention'));

sim_data1 = xml2structWrapper(paramFile1); % Simulation parameters
sim_data1.laser.txSequence = Codes.propCode(sim_data1.laser.codeLength,1);

sim_data2 = xml2structWrapper(paramFile2); % Simulation parameters
sim_data2.laser.txSequence = Codes.propCode(sim_data2.laser.codeLength,1); 
% sim_data2.laser.txSequence = repelem(sim_data1.laser.txSequence,2); % Repeat each symbol twice to get a double length code


for i_ref = 1:length(reflectivity)
    targtDist1_arr = zeros(compare_reps,1);
    targtDist2_arr = zeros(compare_reps,1);
    %----------------------------------------------------------------------------------------------------------------------------------------
    sim_data1.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    sim_data2.environment.wavelengthReflectivityFactor = reflectivity(i_ref);   
    
    for k = 1:compare_reps
        [targtDist1_arr(k)] = runSimAndcalcTargetDistance(sim_data1);
        
        [targtDist2_arr(k)] = runSimAndcalcTargetDistance(sim_data2);
        disp(['Finished ' num2str(k) '/' num2str(compare_reps) ' rounds']);
    end
    disp(['Reflectivity = ' num2str(reflectivity(i_ref))]);
    if nargin() == 6
        dispAndSaveDistCompare(targtDist1_arr, targtDist2_arr, sim_data1, sim_data2, out_dir, [file_name '_' num2str(reflectivity(i_ref))]);
    else
        dispAndSaveDistCompare(targtDist1_arr, targtDist2_arr, sim_data1, sim_data2);
    end
end
end



