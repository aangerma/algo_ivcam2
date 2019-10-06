function [ results ] = calculateFOVFromZ( im,regs,calibParams,runParams )
notNoiseIm = calcLaserBounds(im,calibParams);
imFull = im.i(:,:,1) > 0;
if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
    load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
else
    tpsUndistModel = [];
end

results.mirror.minMaxAngX = minMaxAngle(imFull,2,regs,tpsUndistModel);
results.mirror.minMaxAngY = minMaxAngle(imFull,1,regs,tpsUndistModel);
results.laser.minMaxAngX = minMaxAngle(notNoiseIm,2,regs,tpsUndistModel);
results.laser.minMaxAngY = minMaxAngle(notNoiseIm,1,regs,tpsUndistModel);
    

end
function angles = minMaxAngle(spBinIm,axis,regs,tpsUndistModel)
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
vUnit = Calibration.Undist.undistByTPSModel( vUnit',tpsUndistModel )';% 2D Undist, transpose because input is 3xN and function expects Nx3
if axis == 1 % y angle
    angles = atand(vUnit(2,:)./vUnit(3,:));
else % x angles
    angles = atand(vUnit(1,:)./vUnit(3,:));
end
end
function notNoiseIm = calcLaserBounds(im,calibParams)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.
z = single(im.z);
z(z==0) = nan;%randi(9000,size(zCopy(z==0)));
stdZ = nanstd(z,[],3);
stdZ(isnan(stdZ)) = inf;
notNoiseIm = (stdZ<calibParams.roi.zSTDTh) & (sum(~isnan(z),3) == size(z,3));
se = strel('disk',calibParams.roi.diskSz);
notNoiseIm = imclose(notNoiseIm,se);


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


