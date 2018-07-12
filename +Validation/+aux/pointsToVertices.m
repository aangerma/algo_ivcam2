function v = toVertices(points, zImg, matK)

zMaxSubMM = 8;
sz=size(zImg);

zImg(isnan(zImg)) = 0;
zImg = fillHolesMM(zImg);
zImg = fillHolesMM(zImg);

zImg = double(zImg)/double(zMaxSubMM);

[xi,yi]=meshgrid(0:sz(2)-1,0:sz(1)-1);

u = points(:,1);
v = points(:,2);
z = interp2(xi, yi, zImg, u, v);
    
matKi=double(matK)^-1;
tt = z'.*[u';v';ones(1,numel(v))];
v = (matKi*tt)';
    
end

