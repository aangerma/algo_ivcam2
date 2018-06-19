function e = gridError(v, squareSize)



sn = round(sqrt(size(v, 1)));
[sy, sx] = ndgrid((1:sn)*squareSize, (1:sn)*squareSize);

n = size(v, 1);

[iy, ix] = ndgrid(1:n, 1:n);
X = ix(:);
Y = iy(:);

dv = sqrt((v(X,1)-v(Y,1)).^2 + (v(X,2)-v(Y,2)).^2 + (v(X,3)-v(Y,3)).^2);
ds = sqrt((sx(X)-sx(Y)).^2 + (sy(X)-sy(Y)).^2);

e = sqrt(sum((dv-ds).^2))/n;

end
