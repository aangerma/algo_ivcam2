function V = imgToVertices(zImg, matK, mask)

zMaxSubMM = 8;
sz=size(zImg);

zImg(isnan(zImg)) = 0;
%zImg = fillHolesMM(zImg);
%zImg = fillHolesMM(zImg);

zImg = double(zImg)/double(zMaxSubMM);

[v,u]=ndgrid(0:sz(1)-1,0:sz(2)-1);

if (exist('mask', 'var'))
    mask = and(mask, zImg ~= 0);
else
    mask = (zImg ~= 0);
end

z = zImg(mask);
u = u(mask);
v = v(mask);

matKi=double(matK)^-1;
tt = z'.*[u';v';ones(1,numel(v))];
V = (matKi*tt)';
    
end

