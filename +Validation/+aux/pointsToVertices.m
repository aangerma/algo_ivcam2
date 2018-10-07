function v = pointsToVertices(points, z, matK)

u = points(:,1);
v = points(:,2);

if (min(size(z)) == 1)
    zp = z;
else
    zMaxSubMM = 8;
    sz=size(z);
    
    z(isnan(z)) = 0;
    z = fillHolesMM(z);
    z = fillHolesMM(z);
    
    z = double(z)/double(zMaxSubMM);
    
    [xi,yi]=meshgrid(0:sz(2)-1,0:sz(1)-1);
    zp = interp2(xi, yi, z, u, v);
end

matKi=double(matK)^-1;
tt = zp'.*[u';v';ones(1,numel(v))];
v = (matKi*tt)';

end

