function [poly,valsfit] = polyFit1D(u,vals)
% Receives 3 vectors, u and v are the variables, vals is the target values.
% Fit a 2D polynomial such that vals = f(u,v)
% valsfit is the valus of the polinomial at the points.
% polyx is a function handle that given a (u,x) pair outputs the value
u = u(:);  vals = vals(:);
data = [ones(size(u)),u,u.*u];
polyvars = inv(data'*data)*data'*vals;
poly = @(x) [ones(size(x(:))),x(:),x(:).^2]*polyvars;
valsfit = poly(u);    

end

