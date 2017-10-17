% we want to simulate the undistortion so our xy map will be correct

%% get raw data - distance from lens = 1m; points are in mm
%FileName = 'distortionOld.txt';
FileName = 'distortion_1P_Fresnel.txt';
FID = fopen(FileName);
CStr = textscan(FID, '%s', 'delimiter', '\n');
fclose(FID);

CStr = CStr{1};
CStr = CStr(15:2615);

spl = cellfun(@(x) strsplit(x,' '),CStr,'uni',0);

getColFunAux = @(colInd) cellfun(@(y) str2double(y{colInd}),spl,'uni',0);
getColFun = @(colInd) cell2mat(getColFunAux(colInd));


x = getColFun(6);
y = getColFun(7);

xdist = getColFun(8);
ydist = getColFun(9);

%% work on data
%NORMALIZE THE input to [-1,1]
nx = max(x(:));
ny = max(y(:));
x = x./nx;
xdist = xdist./nx;
y = y./ny;
ydist = ydist./ny;

figure(1);clf
plot(x,y,'*b');hold on;plot(xdist,ydist,'*r')
legend('given undist', 'dist')

%barrel/pincushin distort + Tangential distortion:
%the distortion is radial, and we can find the ratio between Rundist & Rdist like so:
% Rdist/Rundist = Xdist/Xundist = Ydist/Yundist =  1 + k1*Rundist^2 + k2*Rundist^4 + k3*Rundist^6 + ...
% NOTE: aviad added r, r^3 r^5 for better results
r = sqrt((x).^2+(y).^2);
rdist = sqrt((xdist).^2+(ydist).^2);
A = [r r.^2 r.^3 r.^4 r.^5 r.^6];


b = rdist./r -1;
A(1301,:) = []; %x & y are zero in this line...
b(1301,:) = [];
c = A\b

x(1301) = [];
y(1301) = [];
xr = (A*c+1).*x;
yr = (A*c+1).*y;

figure(2);clf
plot(xdist,ydist,'*b');hold on;
plot(yr,xr,'or')
legend('dist','reconstructed dist')





% % angx = atand(x./distFromLens);
% % angy = atand(y./distFromLens);
% % [x,y] = Pipe.DIGG.ang2xy(angx(:),angy(:),regs,Logger(),[]);
% % x = double(x)./(2^shift);y = double(y)./(2^shift);
% % angx = atand(xdist./distFromLens);
% % angy = atand(ydist./distFromLens);
% % [xdist,ydist] = Pipe.DIGG.ang2xy(angx(:),angy(:),regs,Logger(),[]);
% % xdist = double(xdist)./(2^shift);ydist = double(ydist)./(2^shift);