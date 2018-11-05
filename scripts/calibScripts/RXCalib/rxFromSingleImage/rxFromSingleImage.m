clear
fw = Pipe.loadFirmware('\\tmund-MOBL1\C$\source\algo_ivcam2\scripts\calibScripts\DODCalib\DODCalibDataset\initConfigCalib');
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

%% Doesn't look good enough, and has 2 z values per xy and has holes.  
% I shall try a 3D ellipsoid fit, the only difference is the constrain that
% the coefficients of the second power are positive.

[polyvars,polyfunc] = ellipsoidFit3D(x(msk),y(msk),z(msk));

[xx,yy] = meshgrid(linspace(min(x(msk)),max(x(msk))),linspace(min(y(msk)),max(y(msk))));
[zmi,zpl] = polyfunc(xx,yy);

tabplot;
% hold on
% mesh(xx,yy,reshape(zmi,size(xx)));
hold on
mesh(xx,yy,reshape(zpl,size(xx)));

%% Now, using the polynom formula, I shall find the intersection of each point with the surface.

% take a black point and mark it and the line connecting it to the origin:


% Find the intersection between the line and the surface for each interest
% point
p = [x(msk),y(msk),z(msk)];
c = polyvars(1)*ones(size(p,1),1);
b = p*polyvars(2:4)';
a = [p(:,1).*p(:,2),p(:,1).*p(:,3),p(:,2).*p(:,3),p(:,1).^2,p(:,2).^2,p(:,3).^2]*polyvars(5:10)';
delta = b.^2-4*a.*c;
tmi = -b./(2*a) - sqrt(delta)./(2*a);
tpl = -b./(2*a) + sqrt(delta)./(2*a);

pmi = repmat(tmi,[1,3]).*p;
ppl = repmat(tpl,[1,3]).*p;

distmi = sum((pmi-p).^2,2);
distpl = sum((ppl-p).^2,2);
logicalChoose = repmat(distmi < distpl,[1,3]);
intersetion = logicalChoose.*pmi + (1-logicalChoose).*ppl;
dist = sqrt((distmi < distpl).*distmi + (distmi >= distpl).*distpl);
t = (distmi < distpl).*tmi + (distmi >= distpl).*tpl;

tabplot;
hold on
mesh(xx,yy,reshape(zpl,size(xx)));
randint = 45000;
p0 = [p(randint,1),p(randint,2),p(randint,3)];
plot3([p0(1);0],[p0(2),0],[p0(3),0],'r','linewidth',3)
hold on 
plot3(intersetion(randint,1),intersetion(randint,2),intersetion(randint,3),'go','markersize',15,'markerfacecolor','g')

tabplot;
C = inf(size(x)); 
tmpdist = dist; tmpdist(tmpdist>5) = 5;
C(msk) = tmpdist;
mesh(x,y,z,C),colorbar
hold on


%% For each point in the CB, get its IR and dist;

% The dist is positive if t is below 1:
signDist = dist.*(-1*(t>1) + 1*(t<=1));
IR = floor(d.i(msk)/4)+1;





RX = zeros(64,1);
for i = 1:64
    RX(i) = mean(signDist(IR==i));
end
plot(RX)