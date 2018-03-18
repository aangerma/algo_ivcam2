function [delay] = findPropDelay(rtd)

[gy, gx] = ndgrid(-4:4,-6:6);
gy = gy * 30;
gx = gx * 30;


opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 0.00025;
opt.TolX = inf;
opt.Display='none';

verbose = false;

x0 = [0 0 420 5000];
xL = [-100 -100 300 4000];
xH = [100 100 500 6000];

b = 30; % baseline

[X,e]=fminsearchbnd(@(x) errFunc(x, rtd, gx, gy, b, verbose), x0, xL, xH, opt);
x = X(1);
y = X(2);
z = X(3);
delay = X(4);

fprintf('x:%g, y:%g, z:%g, PD: %g [e: %g]\n', x, y, z, delay, e);

end

function [err] = errFunc(X, rtd, gx, gy, b, verbose)

x = X(1);
y = X(2);
z = X(3);
d = X(4);

dist = sqrt((gx-x).^2+(gy-y).^2+z.^2) + sqrt((gx-x-b).^2+(gy-y).^2+z.^2) - (rtd-d);
err = sqrt(sum(dist(:).^2))/numel(rtd);

if verbose
    fprintf('x:%g, y:%g, z:%g, PD: %g [e: %g]\n', x, y, z, d, err);
end

end