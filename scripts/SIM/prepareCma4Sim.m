function [cma] = prepareCma4Sim(depth, code_length, comparator_frequency, do_avg_all)  
cma_temp = reshape(depth, code_length*comparator_frequency,[],1);
if nargin() < 4 || do_avg_all
    cma_temp = round(mean(cma_temp, 2)*127); 
end
assert(max(cma_temp(:))<128); %cma should be always 7b
cma = min(63, bitshift(cma_temp+1,-1));

end