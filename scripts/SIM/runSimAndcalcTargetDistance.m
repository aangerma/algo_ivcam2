function [targtDist] = runSimAndcalcTargetDistance(sim_data)

[depth, sim_data] = run1DSimTxRx(sim_data);

code_reps = ceil(length(depth)/(sim_data.laser.codeLength*sim_data.Comparator.frequency));
depth = depth(sim_data.laser.codeLength*sim_data.Comparator.frequency+1:code_reps*sim_data.laser.codeLength*sim_data.Comparator.frequency);% The first code length is not used

[targtDist] = calcTargetDistance(depth,sim_data);

end