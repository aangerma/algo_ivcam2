function [targt_dist_vec] = dynamic_range_test(dynamic_range, target_dist, code_length, code_reps)
if nargin() < 4
    code_reps = 51;
    if nargin() < 3
        code_length = 52;
    end
end

comparator_freq = 8;

code_reps = code_reps + 1; % The first code length is not used

time_smpl = struct('isTimeLength', false, 'value', code_reps); %[nSec] or number of code repetitions

[depth, p] = run1DSimTxRx(target_dist,code_length, comparator_freq, time_smpl);

code_reps = ceil(length(depth)/(code_length*p.Comparator.frequency));
if ~time_smpl.isTimeLength && code_reps ~= time_smpl.value
    error('Number of code repititions is wrong!');
end

[cma] = prepareCma4Sim(depth, code_reps, code_length, p.Comparator.frequency, false);

code_reps = size(cma, 2);

[regs,luts] = prepareRegsLuts4sim(fullfile('D:\worksapce\ivcam2\algo_ivcam2','+Calibration','initScript'), code_length, 1, p);

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

