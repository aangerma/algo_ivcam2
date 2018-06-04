function [poly,valsfit] = polyFit2D(u,v,vals)
% Receives 3 vectors, u and v are the variables, vals is the target values.
% Fit a 2D polynomial such that vals = f(u,v)
% valsfit is the valus of the polinomial at the points.
% polyx is a function handle that given a (u,x) pair outputs the value
u = u(:); v=v(:); vals = vals(:);
data = [ones(size(u)),u,v,u.*v,u.*u,v.*v];
polyvars = data\vals;
poly = @(x,y) [ones(size(x(:))),x(:),y(:),x(:).*y(:),x(:).^2,y(:).^2]*polyvars;
valsfit = poly(u,v);    

end

