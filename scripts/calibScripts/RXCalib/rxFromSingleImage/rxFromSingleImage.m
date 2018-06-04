clear
fw = Pipe.loadFirmware('\\tmund-MOBL1\C$\source\algo_ivcam2\scripts\calibScripts\DODCalib\DODCalibDataset\initScript');
recordspath = 'X:\Users\tmund\calibScripts\DODCalib\DODCalibDataset\recordedData';

[regs,luts] = fw.get();
verbose = 1;
useLarge = 0;


baseName = 'regularCB_';
N = 24;

fname = fullfile(recordspath,strcat(baseName,num2str(0,'%0.2d'),'.mat'));
load(fname);

%% Use d.z and regs to get the 3d points
msk = cbMask(d.i);

if ~regs.DEST.depthAsRange
    [~,r] = Pipe.z16toVerts(d.z,regs);
else
    r = double(d.z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
end
% get rtd from r
[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);

r= (0.5*(rtd.^2 - regs.DEST.baseline2))./(rtd - regs.DEST.baseline.*sing);
z = r.*cosw.*cosx;
x = r.*cosw.*sinx;
y = r.*sinw;

x(~msk) = inf;y(~msk) = inf;z(~msk) = inf;
tabplot;
mesh(x,y,z)

%% use a 2d parametrization
hold on 
[u,v] = meshgrid(1:size(d.i,2),1:size(d.i,1));
[polyx,xfit] = polyFit2D(u(msk),v(msk),x(msk));
[polyy,yfit] = polyFit2D(u(msk),v(msk),y(msk));
[polyz,zfit] = polyFit2D(u(msk),v(msk),z(msk));

xfixed  = x; xfixed(msk) = xfit;
yfixed  = y; yfixed(msk) = yfit;
zfixed  = z; zfixed(msk) = zfit;
tabplot;
mesh(xfixed,yfixed,zfixed)

%% Doesn't look good, I shall try a 3D polinomial fit
[polyvars,polyfunc] = polyFit3D(x(msk),y(msk),z(msk));

[xx,yy] = meshgrid(linspace(min(x(msk)),max(x(msk))),linspace(min(y(msk)),max(y(msk))));
[zmi,zpl] = polyfunc(xx,yy);

tabplot;
hold on
mesh(xx,yy,reshape(zmi,size(xx)));
hold on
mesh(xx,yy,reshape(zpl,size(xx)));

