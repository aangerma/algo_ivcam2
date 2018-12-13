function [targtDist] = calcTargetDistance(depth, sim_data, verbose)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs:
% depth - the depth data from the Tx-Rx simulation
% sim_data - a structure with all the data required for the simulation
% verbose - optional and true if display is needed
% % Output: 
% targtDist - target distance calculated after fine correlation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[cma] = prepareCma4Sim(depth, sim_data.laser.codeLength, sim_data.Comparator.frequency);

[regs,luts] = prepareRegsLuts4sim(fullfile('D:\worksapce\ivcam2\algo_ivcam2','+Calibration','initScript'), sim_data.laser.codeLength, 1, sim_data);

[cor] = runCoarseCorr(cma, regs, luts);

[~, maxIndDec] = max(cor);
corrOffset = uint8(maxIndDec-1);
corrOffset = permute(corrOffset,[2 3 1]);
[corrSegment] = runFineCorr(cma, regs, luts, corrOffset);

[targtDist] = calcDepth(corrSegment,corrOffset, regs);
if nargin() < 3 || ~verbose
    return;
end

%----------------------------------------------------------------------------------------------------------------------------------------
% Display results
figure;
plot(1:length(cor) ,cor); title(['Coarse Corr: Code length = ' num2str(sim_data.laser.codeLength) ', target distance = ' num2str(target_dist) ', # of code reps = ' num2str(code_reps-1)]);
axis tight;

figure;
plot(1:length(corrSegment) ,corrSegment); title(['Fine Corr: Code length = ' num2str(sim_data.laser.codeLength) ', target distance = ' num2str(target_dist) ', # of code reps = ' num2str(code_reps-1)]);
axis tight;

end