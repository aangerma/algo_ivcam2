function [delay, X, e] = findPropDelay(rtd, verbose)

[gy, gx] = ndgrid(-4:4,-6:6);
gy = gy * 30;
gx = gx * 30;


opt.maxIter=1000;
opt.OutputFcn=[];
opt.TolFun = 0.0025;
opt.TolX = inf;
opt.Display='none';

x0 = [0 0 420 0 5000];
xL = [-300 -100 300 -1.0 4800];
xH = [300 100 700 1.0 5200];

b = 30; % baseline

[X,e]=fminsearchbnd(@(x) errFunc(x, rtd, gx, gy, b, verbose), x0, xL, xH, opt);
[X,e]=fminsearchbnd(@(x) errFunc(x, rtd, gx, gy, b, verbose), X, xL, xH, opt);
x = X(1);
y = X(2);
z = X(3);
fi = X(4);
delay = X(5);

fprintf('x:%g, y:%g, z:%g, fi: %g, PD: %g [e: %g]\n', x, y, z, fi, delay, e);

end

function [err] = errFunc(X, rtd, gx, gy, b, verbose)

x = X(1);
y = X(2);
z = X(3);
fi = X(4);
d = X(5);

dist = sqrt((gx-x).^2+(gy-y).^2+z.^2) + sqrt((gx-x-b*cos(fi)).^2+(gy-y).^2+(z-b*sin(fi)).^2) - (rtd-d);
%dist = sqrt((gx-x).^2+(gy-y).^2+z.^2) + sqrt((gx-x-b).^2+(gy-y).^2+z.^2) - (rtd-d);
err = sqrt(sum(dist(:).^2))/numel(rtd);
%err = sqrt(sum(dist(:).^2))/numel(rtd);
%err = sum(abs(dist(:)))/numel(rtd);

if verbose
    fprintf('x:%7.2f y:%7.2f z:%7.2f fi:%5.2f PD: %7.2f [e: %7.3f]\n', x, y, z, fi, d, err);
end

end