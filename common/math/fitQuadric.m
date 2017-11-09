function [coeffs, x0, y0, w] =fitQuadric(mat)
if(numel(mat)<=6)
    mat=padarray(mat,[1 1],'replicate');
end
[xg, yg] = meshgrid(1:size(mat,2),1:size(mat,1));
xg=xg(:);yg=yg(:);
H=[xg.^2 yg.^2 2*xg.*yg xg yg xg*0+1];
y = -2*log(max(1e-20,mat(:)));
coeffs = H\y;
a = coeffs(1);
b = coeffs(2);
c = coeffs(3);
d = coeffs(4);
e = coeffs(5);
f = coeffs(6);

dt = a*b-c*c;
x0=(-b*d+c*e)/dt;
y0=(c*d-a*e)/dt;
w=exp(-0.5* (f-(a*x0*x0 + b*y0*y0 + c*x0*y0)));
end