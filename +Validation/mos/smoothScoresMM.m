function [ smS ] = smoothScoresMM( s )

s(isnan(s)) = 0;
sp = padarray(s, [1 1 1 1], 'replicate', 'both');

[I1,I2,I3,I4] = ndgrid(-1:1,-1:1,-1:1,-1:1);
sizeC = numel(I1);
cs = zeros([sizeC numel(s)]); 
for i=1:sizeC
    cs(i,:) = vec(sp((2:end-1)+I1(i),(2:end-1)+I2(i),(2:end-1)+I3(i),(2:end-1)+I4(i))); 
end

nValids = sum(cs ~= 0, 1);
ind1 = (nValids == 1);
ind2 = (nValids == 2);
ind3 = (nValids >= 3);

CS = double(sort(cs, 1));

Cv = zeros(size(s));
Cv(ind1) = CS(sizeC,ind1);
Cv(ind2) = (CS(sizeC,ind2) + CS(sizeC-1,ind2))/2;
CS3 = CS(:,ind3);
mi = (sizeC - nValids) + ceil(nValids/2);
mi = mi(ind3);
C1 = CS3(sub2ind(size(CS3), mi-1, 1:size(CS3,2)));
C2 = CS3(sub2ind(size(CS3), mi, 1:size(CS3,2)));
C3 = CS3(sub2ind(size(CS3), mi+1, 1:size(CS3,2)));

Cv(ind3) = (C1 + C3 + C2*2)/4;

smS = reshape(Cv, size(s));

filledS = s;
filledS(s == 0) = smS(s == 0);

end


