function [targtDist1_arr, targtDist2_arr] = runSimWithCodeDuplic(reflectivity, compare_reps, paramFile, out_dir, file_name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comparison over changing target reflectivity between a code and the code 
% concatenation to itself with half repetiotions 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sim_data1 = xml2structWrapper(paramFile); % Simulation parameters
sim_data2 = xml2structWrapper(paramFile); % Simulation parameters
sim_data1.laser.txSequence = Codes.propCode(sim_data1.laser.codeLength,1);
sim_data2.laser.txSequence = [sim_data1.laser.txSequence;sim_data1.laser.txSequence]; % Code is concatenated to itself
sim_data2.laser.codeLength = 2*sim_data1.laser.codeLength;
code_reps1 = 3; 

sim_data1.runTime = code_reps1*sim_data1.laser.codeLength;
sim_data2.runTime = sim_data1.runTime;

for i_ref = 1:length(reflectivity)
    targtDist1_arr = zeros(compare_reps,1);
    targtDist2_arr = zeros(compare_reps,1);
    sim_data1.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    sim_data2.environment.wavelengthReflectivityFactor = reflectivity(i_ref);
    for k = 1:compare_reps
        [depth, ~] = run1DSimTxRx(sim_data1);
        depth = depth(sim_data1.laser.codeLength*sim_data1.Comparator.frequency+1:code_reps1*sim_data1.laser.codeLength*sim_data1.Comparator.frequency);% The first code length is not used
        
        [targtDist1_arr(k)] = calcTargetDistance(depth,sim_data1);
        
        [targtDist2_arr(k)] = calcTargetDistance(depth,sim_data2);
        
        disp(['Finished ' num2str(k) '/' num2str(compare_reps) ' rounds']);
    end
    
    dispAndSaveDistCompare(targtDist1_arr, targtDist2_arr, sim_data1, sim_data2, out_dir, [file_name '_' num2str(reflectivity(i_ref))]);
end

end

