function [e1, e2] = gridError(v, gridSize, squareSize)

n = size(v, 1);
if (n ~= gridSize(1)*gridSize(2))
    error('Validation:gridError: gridSize and the vertex number do not match');
end

[sy, sx] = ndgrid((1:gridSize(1))*squareSize, (1:gridSize(2))*squareSize);


[iy, ix] = ndgrid(1:n, 1:n);
X = ix(:);
Y = iy(:);

dv = sqrt((v(X,1)-v(Y,1)).^2 + (v(X,2)-v(Y,2)).^2 + (v(X,3)-v(Y,3)).^2);
ds = sqrt((sx(X)-sx(Y)).^2 + (sy(X)-sy(Y)).^2);

e1 = mean(abs(dv-ds));
e2 = sqrt(mean((dv-ds).^2));

end
