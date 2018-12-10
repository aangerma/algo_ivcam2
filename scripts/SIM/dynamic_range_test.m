function [targt_dist_vec] = dynamic_range_test(dynamic_range, sim_data)

[depth, ~] = run1DSimTxRx(sim_data);

code_reps = sim_data.runTime/sim_data.laser.codeLength;
[cma] = prepareCma4Sim(depth, code_reps, sim_data.laser.codeLength, sim_data.Comparator.frequency, false);

code_reps = size(cma, 2);

[regs,luts] = prepareRegsLuts4sim(fullfile('D:\worksapce\ivcam2\algo_ivcam2','+Calibration','initScript'), sim_data.laser.codeLength, 1, sim_data);

targt_dist_vec = zeros(code_reps, 1);

for k = 1:code_reps
    
    [cor] = runCoarseCorr(cma(:,k), regs, luts, dynamic_range);
    
    [~, maxIndDec] = max(cor);
    corrOffset = uint8(maxIndDec-1);
    corrOffset = permute(corrOffset,[2 3 1]);
    [corrSegment] = runFineCorr(cma(:,k), regs, luts, corrOffset);
    
    [targt_dist_vec(k)] = calcDepth(corrSegment,corrOffset, regs);
end

end

