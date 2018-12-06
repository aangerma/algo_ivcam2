function [cma] = prepareCma4Sim(depth, code_reps, code_length, comparator_frequency, do_avg_all)  
cma_temp = depth(1:code_reps*code_length*comparator_frequency);
cma_temp = reshape(cma_temp, code_length*comparator_frequency,[],1);
cma_temp = cma_temp(:,2:end);
if nargin() < 5 || do_avg_all
    cma_temp = round(mean(cma_temp, 2)*127); % The first code length is not used
end
assert(max(cma_temp(:))<128); %cma should be always 7b
cma = min(63, bitshift(cma_temp+1,-1));

end