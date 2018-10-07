function [ results ] = validateFOV( hw,regs,FE )
%VALIDATEFOV returns a struct that details the fov of the mirror
%and that of the laser (smaller than that of the mirror). In addition, it
%calculates the min and max angles of projection when scanning up and
%scanning down.
if ~exists('FE','var')
   FE = []; 
end

r = Calibration.RegState(hw);
r.add('DIGGsphericalEn'    ,true     );
r.set();
hw.cmd('iwb e2 06 01 00'); % Remove bias
Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],'Please Make Sure Borders Are Bright');
[imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);
r.reset();
hw.cmd('iwb e2 06 01 70'); % Return bias

fullIm = imU > 0;
notNoiseImU = calcLaserBounds(imU);
notNoiseImD = calcLaserBounds(imD);
        
results.mirror.minMaxAngX = minMaxAngle(fullIm,2,regs,FE);
results.mirror.minMaxAngY = minMaxAngle(fullIm,1,regs,FE);
results.laser.minMaxAngXup = minMaxAngle(notNoiseImU,2,regs,FE);
results.laser.minMaxAngYup = minMaxAngle(notNoiseImU,1,regs,FE);
results.laser.minMaxAngXdown = minMaxAngle(notNoiseImD,2,regs,FE);
results.laser.minMaxAngYdown = minMaxAngle(notNoiseImD,1,regs,FE);
    

end
function angles = minMaxAngle(spBinIm,axis,regs,FE)
if axis == 1 % Y angle
    xp = regs.GNRL.imgHsize/2;
    ymin = find(spBinIm(:,xp),1);
    ymax = find(spBinIm(:,xp),1,'last');
    yy = double([ymin,ymax]');
    xx = double([xp,xp]'*4);
    
else % X angle
    yp = regs.GNRL.imgVsize/2;
    xmin = find(spBinIm(yp,:),1);
    xmax = find(spBinIm(yp,:),1,'last');
    yy = double([yp,yp]');
    xx = double([xmin,xmax]'*4);
    
end
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));
angx = single(xx);
angy = single(yy);

vUnit = Calibration.aux.ang2vec(angx,angy,regs,FE);
if axis == 1 % y angle
    angles = atand(vUnit(2,:)./vUnit(3,:));
else % x angles
    angles = atand(vUnit(1,:)./vUnit(3,:));
end
end
function notNoiseIm = calcLaserBounds(im)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.

binaryIm = im > 0;
stats = regionprops(binaryIm);
leftCol = ceil(stats(1).BoundingBox(1));
rightCol = leftCol+stats(1).BoundingBox(3);

% Use the 3 outermost columns for nest estimation
noiseValues = im(:,[leftCol:leftCol+2,rightCol-2:rightCol]);
noiseThresh = max(noiseValues(noiseValues>0));

% Find noise pixels
% noiseIm = (im > 0) .* (im <= noiseThresh);
notNoiseIm = im > noiseThresh;
end
