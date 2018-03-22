function [ filledI ] = fillHolesMM( I )

Ip = padarray(I, [1 1], 'replicate', 'both');
C = im2col(Ip, [3 3], 'sliding');

nValids = sum(C ~= 0, 1);
ind1 = (nValids == 1);
ind2 = (nValids == 2);
ind3 = (nValids >= 3);

CS = double(sort(C, 1));

Cv = zeros(size(I));
Cv(ind1) = CS(9,ind1);
Cv(ind2) = (CS(8,ind2) + CS(9,ind2))/2;
CS3 = CS(:,ind3);
mi = (9 - nValids) + ceil(nValids/2);
mi = mi(ind3);
C1 = CS3(sub2ind(size(CS3), mi-1, 1:size(CS3,2)));
C2 = CS3(sub2ind(size(CS3), mi, 1:size(CS3,2)));
C3 = CS3(sub2ind(size(CS3), mi+1, 1:size(CS3,2)));

Cv(ind3) = (C1 + C3 + C2*2)/4;

smI = cast(reshape(Cv, size(I)), class(I));

filledI = I;
filledI(I == 0) = smI(I == 0);

end


