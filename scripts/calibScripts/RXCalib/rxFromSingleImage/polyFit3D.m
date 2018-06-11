function [polyvars,polyfunc] = polyFit3D(x,y,z)
%POLYFIT3D Summary of this function goes here
%   Detailed explanation goes here
x = x(:); y = y(:); z = z(:);

data = [ones(size(x)), x,y,z,x.*y,x.*z,y.*z,x.^2,y.^2,z.^2];
Q = data'*data;
[U,~,~] = svd(Q);
polyvars = U(:,end);

polyfunc = @(x_,y_) getZfromXY(x_,y_,polyvars);
end

function [zmin,zplus] = getZfromXY(x,y,p)
x = x(:);
y = y(:);
c = p(1)+p(2)*x+p(3)*y+p(5)*x.*y+p(8)*x.^2+p(9)*y.^2;
b = p(4)+p(6)*x+p(7)*y;
a = p(10)*ones(size(c));

zmin = inf(size(x));
zplus = inf(size(x));
delta = b.^2-4*a.*c;

zmin(delta>=0) = -b(delta>=0)./(2*a(delta>=0)) - sqrt(delta(delta>=0))./(2*a(delta>=0));
zplus(delta>=0) = -b(delta>=0)./(2*a(delta>=0)) + sqrt(delta(delta>=0))./(2*a(delta>=0));



end