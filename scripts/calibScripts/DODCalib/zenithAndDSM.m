% Load some fw
fw = Pipe.loadFirmware('\\tmund-MOBL1\C$\source\algo_ivcam2\scripts\calibScripts\DODCalib\DODCalibDataset\initScript');
regs2.FRMW.gaurdBandV = single(0);
fw.setRegs(regs2,'');
[regs,luts] = fw.get();
regs.FRMW.gaurdBandV
% Create a grid of angles:
[angx,angy] = meshgrid([-2047,0,2047],[-2047,0,2047]);

% Show them on the xy image plane
[xf,yf] = myang2xy(angx,angy,regs);
plot(xf(:),yf(:),'*');
rectangle('position',[0 0 double(regs.GNRL.imgHsize-1) double(regs.GNRL.imgVsize-1)])


%% I want to show that adding a zenith of a certain angle is equivilant to a dsm offset
% Assuming 2047 represents the fov/4, I shall add to the x angle an offset of fov/8.
maxAng = 2047;
[angx,angy] = meshgrid([-maxAng/2,0,maxAng/2],[-maxAng/2,0,maxAng/2]);
[angx,angy] = meshgrid([-maxAng,0,maxAng],[-maxAng,0,maxAng]);
% angx = [-maxAng,-maxAng,-maxAng];
% angy = [maxAng,0,-maxAng];
offSetAngle = (regs.FRMW.xfov/4);
figure
% Get the x,y coordinates with xOffset 
xoffset = offSetAngle / (regs.FRMW.xfov/4) * 2047;
[xfOff,yfOff,xynrmOff] = myang2xy(angx+xoffset,angy,regs);
plot(xfOff(:),yfOff(:),'*'); 
hold on;
rectangle('position',[0 0 double(regs.GNRL.imgHsize-1) double(regs.GNRL.imgVsize-1)])
% Get the x,y coordinates with zenith of the same angle
regsZ = regs;
regsZ.FRMW.laserangleH = -single(offSetAngle);
[xfZ,yfZ,xynrmZ] = myang2xy(angx,angy,regsZ);
plot(xfZ(:),yfZ(:),'*');

% rescale points after offset
ya = (yfZ(3,2)-yfZ(1,2))/(yfOff(3,2)-yfOff(1,2));
yb = -yfOff(1,2)*ya;
yfOffTr = yfOff*ya + yb;
xa = (xfZ(2,3)-xfZ(2,1))/(xfOff(2,3)-xfOff(2,1));
xb = -xfOff(2,1)*xa;
xfOffTr = xfOff*xa + xb;
plot(xfOffTr(:),yfOffTr(:),'g*');
% We can see that the zenith doesn't act as expected
%% I know! Even when the mirror is aimed at the zenith, the vertical scanline won't be a vertical line in the image plane. However, I do believe the 3d representation of the images is the same.
% I shall load a CB image, calculate its (range,angx,angy) , and calculate
% the 3D error with a zenith and its angle.
