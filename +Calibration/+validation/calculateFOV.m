function [ results ] = calculateFOV( imU,imD,imNoise,regs,calibParams )
noiseThresh = max(imNoise(:));
noiseThresh = noiseThresh*calibParams.roi.noiseMarginFactor;
fullIm = imU > 0;
notNoiseImU = calcLaserBounds(imU,noiseThresh);
notNoiseImD = calcLaserBounds(imD,noiseThresh);
        
results.mirror.minMaxAngX = minMaxAngle(imNoise,2,regs);
results.mirror.minMaxAngY = minMaxAngle(imNoise,1,regs);
results.laser.minMaxAngXup = minMaxAngle(notNoiseImU,2,regs);
results.laser.minMaxAngYup = minMaxAngle(notNoiseImU,1,regs);
results.laser.minMaxAngXdown = minMaxAngle(notNoiseImD,2,regs);
results.laser.minMaxAngYdown = minMaxAngle(notNoiseImD,1,regs);
    

end
function angles = minMaxAngle(spBinIm,axis,regs)
if axis == 1 % Y angle
    xp = regs.GNRL.imgHsize/2;
    ymin = find(spBinIm(:,xp),1);
    ymax = find(spBinIm(:,xp),1,'last');
    yy = double([ymin,ymax]');
    xx = double(([xp,xp]'-0.5)*4);
    
else % X angle
    yp = regs.GNRL.imgVsize/2;
    xmin = find(spBinIm(yp,:),1);
    xmax = find(spBinIm(yp,:),1,'last');
    yy = double([yp,yp]');
    xx = double(([xmin,xmax]'-0.5)*4);
    
end
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));
angx = single(xx);
angy = single(yy);

[angx,angy] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
vUnit = Calibration.aux.ang2vec(angx,angy,regs);
% (To add) 2D Undist - 
% v = Calibration.Undist.undistByTPSModel( v',[],runParams )';
if axis == 1 % y angle
    angles = atand(vUnit(2,:)./vUnit(3,:));
else % x angles
    angles = atand(vUnit(1,:)./vUnit(3,:));
end
end
function notNoiseIm = calcLaserBounds(im,noiseThresh)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.
binaryIm = im > 0;
[binaryIm,stats] = maxAreaStat(binaryIm,size(im));% Keep only the largest connected component.
im(~binaryIm) = 0;
leftCol = ceil(stats.BoundingBox(1));
rightCol = min(leftCol+stats.BoundingBox(3),size(im,2));

% Use the 3 outermost columns for nest estimation
noiseValues = im(:,[leftCol:leftCol+2,rightCol-2:rightCol]);
% noiseThresh = max(noiseValues(noiseValues>0));

% Find noise pixels
% noiseIm = (im > 0) .* (im <= noiseThresh);
notNoiseIm = im > noiseThresh;
end
function [binIm1stat,stat] = maxAreaStat(binaryIm,sz)
st = regionprops(binaryIm);
for i = 1:numel(st)
%     hold on
%     rectangle('Position',[st(i).BoundingBox(1),st(i).BoundingBox(2),st(i).BoundingBox(3),st(i).BoundingBox(4)],...
%         'EdgeColor','r','LineWidth',2 )
    area(i) = st(i).BoundingBox(3)*st(i).BoundingBox(4)/(prod(sz));
end
[m,mI] = max(area);
if m < 0.8
    warning('Largest connected region in image covers only %2.2g of the image.',m);
end
stat = st(mI);
% Remove the smaller stats from the image
binIm1stat = binaryIm;
for i = 1:numel(st)
    if i~=mI
       iC = ceil(st(i).BoundingBox(1)):floor(st(i).BoundingBox(1)+st(i).BoundingBox(3));
       iR = ceil(st(i).BoundingBox(2)):floor(st(i).BoundingBox(2)+st(i).BoundingBox(4));
       binIm1stat(iR,iC) = 0;
    end
end

end


