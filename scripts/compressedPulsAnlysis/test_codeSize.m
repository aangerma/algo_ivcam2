clear;
mx = nan(26,1);

for N = 6:26;
    codes = getAllValidCodes(N);
    score=zeros(size(codes,1),1);
    c={};
    ind = mod(bsxfun(@plus,(1:N)',0:N-1)-1,N)+1;
    parfor i=1:size(codes,1)
        ci = codes(i,:);
        c{i}=sum(~bsxfun(@xor,ci,ci(ind)),2);
        cs = sort(c{i});
        score(i) = (cs(end)-cs(end-1));
    end
    mx(N)=max(score);
    
end
mxE = floor(((1:N)-1)/4)*2;
plot(1:N,mx,1:N,mxE);
