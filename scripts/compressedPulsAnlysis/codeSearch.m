function codeSearch
rng(1)
N= 256;

batchSize = 2^20;
bestPSLD=inf;

while(true)
    cand = rand(N/2,batchSize)>.5;
    cand=reshape(permute(cat(3,cand,~cand),[3 1 2]),N,batchSize);
    c=double(Utils.correlator(cand,cand,uint32((0:batchSize-1))))*2-N/2;
    m=max(c(3:end-1,:));
    fprintf('.');
    if(any(m<bestPSLD))
        ii=find(m<bestPSLD,1);
        bestPSLD=m(ii);
        bestCode = cand(:,ii);
        fprintf('\n%d %s\n',bestPSLD,num2str(bestCode));
    end
   
end
end

