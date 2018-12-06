function [targtDist] = calcTargetDistance(target_dist,code_length, comparator_freq, time_smpl, verbose)

[depth, p] = run1DSimTxRx(target_dist,code_length, comparator_freq, time_smpl);

code_reps = ceil(length(depth)/(code_length*p.Comparator.frequency));
if ~time_smpl.isTimeLength && code_reps ~= time_smpl.value
    error('Number of code repititions is wrong!');
end

[cma] = prepareCma4Sim(depth, code_reps, code_length, p.Comparator.frequency);

[regs,luts] = prepareRegsLuts4sim(fullfile('D:\worksapce\ivcam2\algo_ivcam2','+Calibration','initScript'), code_length, 1, p);

[cor] = runCoarseCorr(cma, regs, luts);

[~, maxIndDec] = max(cor);
corrOffset = uint8(maxIndDec-1);
corrOffset = permute(corrOffset,[2 3 1]);
[corrSegment] = runFineCorr(cma, regs, luts, corrOffset);

[targtDist] = calcDepth(corrSegment,corrOffset, regs);
if nargin() < 5 || ~verbose
    return;
end

%----------------------------------------------------------------------------------------------------------------------------------------
% Display results
figure;
plot(1:length(cor) ,cor); title(['Coarse Corr: Code length = ' num2str(code_length) ', target distance = ' num2str(target_dist) ', # of code reps = ' num2str(code_reps-1)]);
axis tight;

figure;
plot(1:length(corrSegment) ,corrSegment); title(['Fine Corr: Code length = ' num2str(code_length) ', target distance = ' num2str(target_dist) ', # of code reps = ' num2str(code_reps-1)]);
axis tight;

end

function [cma] = prepareCma4Sim(depth, code_reps, code_length, comparator_frequency)
cma_temp = depth(1:code_reps*code_length*comparator_frequency);
cma_temp = reshape(cma_temp, code_length*comparator_frequency,[],1);
cma_temp = round(mean(cma_temp(:,2:end), 2)*127); % The first code length is not used
assert(max(cma_temp(:))<128); %cma should be always 7b
cma = min(63, bitshift(cma_temp+1,-1));

end