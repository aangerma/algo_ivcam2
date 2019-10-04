function [roiregs,results] = calibROIFromZ( im,regs,calibParams,runParams)
% Calibrate the margins of the image.
% 1. Take a spherical mode icmage of up direction.
% 2. Take a spherical mode image of down direction.
% 3. Find the horizontal margins where we have no laser for both images.
% 4. Find the top/bottom margin for both images, the might be slightly
% diagonal. Do it by taking the values seen at the horizontal margins. Use
% the values to mark the noise pixels in the image. for the top margin,
% calculate the width of the noise for each column. Use the
% median/max/60%/mean of the width as the true margin. Use the minimal
% value of Y left to set the margin. Do it for up and down and use the
% hardest margin. At the end add the extra margins from calibParams.  
%% Get margins for each image
edges = calcBounds(im,calibParams,runParams,regs,'im');

%% Calculate the margins we need to take with minimal crop
calibParamsMinimalCrop = minimalCropParams();
minimalMargins = calcMargins(edges,regs,calibParamsMinimalCrop,runParams);

%% Get the true margins with the paramters from calibParams
margins = calcMargins(edges,regs,calibParams,runParams);


% As weird as it is, extra margins are consistent with FRMWmargin*.
% Therefore Top is actually the bottom of the image (in hw.getFrame),
% Bottom is the top, left is left and right is right. Frame from
% hw.getFrame are rotated by 180 from the real world. Bottom <-> Top
% confusion should be fixed. 
roiregs = margins2regs(margins,regs);

showedPixelsV = single(regs.GNRL.imgVsize) - margins(1) - margins(2); 
showedPixelsH = single(regs.GNRL.imgHsize) - margins(3) - margins(4); 
extraPixels = margins - minimalMargins;
results.extraPixWorldPercT = extraPixels(2)/showedPixelsV*100;
results.extraPixWorldPercB = extraPixels(1)/showedPixelsV*100;
results.extraPixWorldPercL = extraPixels(4)/showedPixelsH*100;
results.extraPixWorldPercR = extraPixels(3)/showedPixelsH*100;
end
function calibParamsMinimalCrop = minimalCropParams()
calibParamsMinimalCrop.roi.cropAroundOpticalAxis = 0;
calibParamsMinimalCrop.roi.maxFovX = [];
calibParamsMinimalCrop.roi.maxFovY= [];
calibParamsMinimalCrop.roi.squarePixelsRatio = [];
calibParamsMinimalCrop.roi.extraMarginT = 0;
calibParamsMinimalCrop.roi.extraMarginB = 0;
calibParamsMinimalCrop.roi.extraMarginL = 0;
calibParamsMinimalCrop.roi.extraMarginR = 0;
calibParamsMinimalCrop.roi.useExtraMargins = 0;

end
function edges = calcBounds(im,calibParams,runParams,regs,description)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.
z = single(im.z);
z(z==0) = nan;%randi(9000,size(zCopy(z==0)));
stdZ = nanstd(z,[],3);
stdZ(isnan(stdZ)) = inf;
notNoiseIm = (stdZ<calibParams.roi.zSTDTh) & (sum(~isnan(z),3) == size(z,3));
% [binaryIm,stats] = maxAreaStat(notNoiseIm,size(notNoiseIm));% Keep only the largest connected component.
% notNoiseIm(~binaryIm) = 0;

se = strel('disk',calibParams.roi.diskSz);
notNoiseIm = imclose(notNoiseIm,se);

% Find the corners of the not noise image - connect them
[xi,yi] = meshgrid(1:size(notNoiseIm,2),1:size(notNoiseIm,1));
xi(~notNoiseIm) = inf;
yi(~notNoiseIm) = inf;
xy = [xi(:),yi(:)];
xyTopLeft = closest2pointL1(xy,[1,1]);
xyTopRight = closest2pointL1(xy,[regs.GNRL.imgHsize,1]);
xyBottomLeft = closest2pointL1(xy,[1,regs.GNRL.imgVsize]);
xyBottomRight = closest2pointL1(xy,[regs.GNRL.imgHsize,regs.GNRL.imgVsize]);

n = 1000;
topEdge = [linspace(xyTopLeft(2),xyTopRight(2),n)',linspace(xyTopLeft(1),xyTopRight(1),n)']; 
bottomEdge = [linspace(xyBottomRight(2),xyBottomLeft(2),n)',linspace(xyBottomRight(1),xyBottomLeft(1),n)']; 
leftEdge = [linspace(xyBottomLeft(2),xyTopLeft(2),n)',linspace(xyBottomLeft(1),xyTopLeft(1),n)']; 
rightEdge = [linspace(xyTopRight(2),xyBottomRight(2),n)',linspace(xyTopRight(1),xyBottomRight(1),n)']; 
imageFrame = [topEdge; rightEdge; bottomEdge; leftEdge];% Add left column


% % Find the right and left margins - index of the pixels that bound the
% % image without the noise.
% leftImIndex = find(diff(noiseColumns)==-1,1,'first')+1;
% rightImIndex = find(diff(noiseColumns)==1,1,'last');
% if isempty(leftImIndex) || leftImIndex>(size(im,2)/2)
%     leftImIndex = find(sum(notNoiseIm)>0,1,'first');
% end
% if isempty(rightImIndex) || rightImIndex<(size(im,2)/2)
%     rightImIndex = find(sum(notNoiseIm)>0,1,'last');
% end
% 
% % The top noise strip of the image is diagonal. Find the pixel where the noise stops for each column.
topEdgeX = (xyTopLeft(1):xyTopRight(1));
topEdgeY = arrayfun(@(x) find(notNoiseIm(:,x)>0,1,'first'), topEdgeX);
topEdge = [topEdgeY',topEdgeX'];
bottomEdgeX = (xyBottomLeft(1):xyBottomRight(1));
bottomEdgeY = arrayfun(@(x) find(notNoiseIm(:,x)>0,1,'last'), bottomEdgeX);
bottomEdge = [bottomEdgeY',bottomEdgeX'];
leftEdgeY = (xyTopLeft(2):xyBottomLeft(2));
leftEdgeX = arrayfun(@(y) find(notNoiseIm(y,:)>0,1,'first'), leftEdgeY);
leftEdge = [leftEdgeY',leftEdgeX'];
rightEdgeY = (xyTopRight(2):xyBottomRight(2));
rightEdgeX = arrayfun(@(y) find(notNoiseIm(y,:)>0,1,'last'), rightEdgeY);
rightEdge = [rightEdgeY',rightEdgeX'];
imageFrame = [topEdge; rightEdge; flipud(bottomEdge); flipud(leftEdge)];% Add left column


ff = Calibration.aux.invisibleFigure; 
imagesc(im.i(:,:,1)); hold on; plot(imageFrame(:,2),imageFrame(:,1),'r','linewidth',2);
title(description);
Calibration.aux.saveFigureAsImage(ff,runParams,'ROI',description)

edges.T = topEdge;
edges.B = bottomEdge;
edges.L = leftEdge;
edges.R = rightEdge;

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
function xyClose = closest2pointL1(xy,p)
    [~,Imin] = min(sum(abs(double(xy)-double(p)),2));
    xyClose = xy(Imin,:);
end
function marginsTBLR = calcMargins(edges,regs,calibParams,runParams)
if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
    load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
else
    tpsUndistModel = [];
end

ang2xy = @(sphericalPixels) spherical2xy(sphericalPixels,regs,tpsUndistModel); 
[edgesXY,edgesTanXY] = structfun(ang2xy,edges,'UniformOutput',false); 
factor = 0.80;

tanMarginsTBLR(1) = (max(edgesTanXY.T(innerIndices(edgesTanXY.T,factor),2)));
tanMarginsTBLR(2) = (min(edgesTanXY.B(innerIndices(edgesTanXY.B,factor),2)));
tanMarginsTBLR(3) = (max(edgesTanXY.L(innerIndices(edgesTanXY.L,factor),1)));
tanMarginsTBLR(4) = (min(edgesTanXY.R(innerIndices(edgesTanXY.R,factor),1)));

extraMargins = [calibParams.roi.extraMarginT,...
                calibParams.roi.extraMarginB,...
                calibParams.roi.extraMarginL,...
                calibParams.roi.extraMarginR]*calibParams.roi.useExtraMargins;
anglesTBLR = atand(tanMarginsTBLR);
% Margins to angles:
anglesTBLR = sign(anglesTBLR).*(abs(anglesTBLR)- extraMargins);
% Crop to a specific field of view
if ~isempty(calibParams.roi.maxFovX) && calibParams.roi.maxFovX<abs(diff(anglesTBLR(3:4))) 
    oldFov = anglesTBLR(4)-anglesTBLR(3);
    newFov = calibParams.roi.maxFovX;
    anglesTBLR(3) = anglesTBLR(3) + (oldFov-newFov)/2;
    anglesTBLR(4) = anglesTBLR(4) - (oldFov-newFov)/2;  
end
if ~isempty(calibParams.roi.maxFovY) && calibParams.roi.maxFovY<abs(diff(anglesTBLR(1:2))) 
    oldFov = anglesTBLR(2)-anglesTBLR(1);
    newFov = calibParams.roi.maxFovY;
    anglesTBLR(1) = anglesTBLR(1) + (oldFov-newFov)/2;
    anglesTBLR(2) = anglesTBLR(2) - (oldFov-newFov)/2;  
end


tanMarginsTBLR = tand(anglesTBLR);

if calibParams.roi.cropAroundOpticalAxis
    tanMarginsTBLR(1:2)= sign(tanMarginsTBLR(1:2)) * min(abs(tanMarginsTBLR(1:2)));
    tanMarginsTBLR(3:4)= sign(tanMarginsTBLR(3:4)) * min(abs(tanMarginsTBLR(3:4)));
end

% If we want square pixels, we should take the largest 4 by 3 rect inside
% the square
if ~isempty(calibParams.roi.squarePixelsRatio)
    expectedRatio = calibParams.roi.squarePixelsRatio(2)/calibParams.roi.squarePixelsRatio(1); 
    if abs(diff(tanMarginsTBLR(1:2)))/abs(diff(tanMarginsTBLR(3:4))) < expectedRatio
        oldLen = tanMarginsTBLR(4)-tanMarginsTBLR(3);
        newLen = abs(diff(tanMarginsTBLR(1:2)))/expectedRatio;
        tanMarginsTBLR(3) = tanMarginsTBLR(3) + (oldLen-newLen)/2;
        tanMarginsTBLR(4) = tanMarginsTBLR(4) - (oldLen-newLen)/2;
    else
        oldLen = tanMarginsTBLR(2)-tanMarginsTBLR(1);
        newLen = abs(diff(tanMarginsTBLR(3:4)))*expectedRatio;
        tanMarginsTBLR(1) = tanMarginsTBLR(1) + (oldLen-newLen)/2;
        tanMarginsTBLR(2) = tanMarginsTBLR(2) - (oldLen-newLen)/2;
    end
end
% Now we have the bounderies of the frame in tanXY domain. We should project them to the image plane so we could use the margin calculation. 
vTBLR = [0 tanMarginsTBLR(1) 1;
         0 tanMarginsTBLR(2) 1;
         tanMarginsTBLR(3) 0 1;
         tanMarginsTBLR(4) 0 1]';
[rectX,rectY] = Calibration.aux.vec2xy(vTBLR, regs);

marginsTBLR(1) = rectY(1);
marginsTBLR(2) = single(single(regs.GNRL.imgVsize)) - rectY(2);
marginsTBLR(3) = rectX(3);
marginsTBLR(4) = single(regs.GNRL.imgHsize) - rectX(4);



marginsTBLR(1:2) = marginsTBLR([2,1]); % marginT actually refers to the bottom of the image and vice versa (names should be swapped)

plotEdges(edgesXY,regs,runParams,rectX,rectY)
end
function plotEdges(edgesXY,regs,runParams,rectX,rectY)
    if ~isempty(runParams)
        ff = Calibration.aux.invisibleFigure; 
        plot(edgesXY.T(:,1),edgesXY.T(:,2),'linewidth',2),hold on
        plot(edgesXY.B(:,1),edgesXY.B(:,2),'linewidth',2),hold on
        plot(edgesXY.L(:,1),edgesXY.L(:,2),'linewidth',2),hold on
        plot(edgesXY.R(:,1),edgesXY.R(:,2),'linewidth',2),hold on
        rectangle('Position',[0,0,regs.GNRL.imgHsize,regs.GNRL.imgVsize],'linewidth',2)
        hold on
        rectangle('Position',[rectX(3),rectY(1),rectX(4)-rectX(3),rectY(2)-rectY(1)],'linewidth',2)
        title('Projected Pincushion in Image Plane');
        Calibration.aux.saveFigureAsImage(ff,runParams,'ROI','Pincushion$CroppedArea',0);
    end
end
function ind = innerIndices(v,factor)
% Return the indices of the inner factor percent of vector rows
vlen = size(v,1);
allInd = 1:vlen;
ind = allInd(uint16(vlen*(1-factor)/2) :uint16(vlen*(1+factor)/2));
end
function [xy,tanxy] = spherical2xy(sphericalPixels,regs,tpsUndistModel)
% angX/angY is translated to xyz using the regs
% Then the xyz is translated to te cordinate in the image plane. If a fov
% expander model is valid, 
        yy = double(sphericalPixels(:,1));
        xx = double((sphericalPixels(:,2)-0.5)*4);
        xx = xx-double(regs.DIGG.sphericalOffset(1));
        yy = yy-double(regs.DIGG.sphericalOffset(2));
        xx = xx*2^10;%bitshift(xx,+12-2);
        yy = yy*2^12;%bitshift(yy,+12);
        xx = xx/double(regs.DIGG.sphericalScale(1));
        yy = yy/double(regs.DIGG.sphericalScale(2));
        angx = single(xx);
        angy = single(yy);
        
        [angx,angy] = Calibration.Undist.applyPolyUndistAndPitchFix(angx,angy,regs);
        v = Calibration.aux.ang2vec(angx,angy,regs);
        v = Calibration.Undist.undistByTPSModel( v',tpsUndistModel )';% 2D Undist
        [x,y] = Calibration.aux.vec2xy(v, regs);
        xy = [x,y];
        tanxy = [(v(1,:)./v(3,:))',(v(2,:)./v(3,:))'];
end
function roiregs = margins2regs(margins,regs)
% y = (1-t)*0 +t*Hsz 
% t1 = L/Hsz
% t2 = 1-R/Hsz
% 0 = -(1-t1)*mL+t1*(Hsz+mR)
% Hsz = -(1-t2)*mL+t2*(Hsz+mR)

% 0 = (L/Hsz-1)*mL +L + L/Hsz*mR
% Hsz = -R/Hsz*mL +Hsz - R + (1 - R/Hsz)*mR

% Ax=B
% A = [L/Hsz-1 , L/Hsz;
%       -R/Hsz, 1-R/Hsz];
% B = [-L
%      R]; 

T = margins(1); B = margins(2);
L = margins(3); R = margins(4);
Vsz = single(regs.GNRL.imgVsize);
Hsz = single(regs.GNRL.imgHsize);

getA = @(m0,m1,sz) [1-m0/sz, -m0/sz; -m1/sz, 1-m1/sz]; 
getB = @(m0,m1,sz) [m0, m1]';

LR = getA(L,R,Hsz)\getB(L,R,Hsz);
BT = getA(B,T,Vsz)\getB(B,T,Vsz);

roiregs.FRMW.calMarginL = int16(LR(1));
roiregs.FRMW.calMarginR = int16(LR(2));
roiregs.FRMW.calMarginB = int16(BT(1));
roiregs.FRMW.calMarginT = int16(BT(2));
% T/Vsz = rT/(Vsz+rT+rB)
% B/Vsz = rB/(Vsz+rT+rB)
% 
% T*Vsz+(T-Vsz)*rT+T*rB = 0
% B*Vsz+B*rT+(B-Vsz)*rB = 0
% 
% T*Vsz+(T-Vsz)*rT  -T/(B-Vsz)*(B*Vsz+B*rT ) = 0
% rT*(T-Vsz-T*B/(B-Vsz)) + T*Vsz - T*B*Vsz/(B-Vsz) = 0
% 
% rT = (-T*Vsz + T*B*Vsz/(B-Vsz)) / (T-Vsz-T*B/(B-Vsz));
% % rB = (-B*Vsz + T*B*Vsz/(T-Vsz)) / (B-Vsz-T*B/(T-Vsz));
% T = margins(1); B = margins(2);
% L = margins(3); R = margins(4);
% Vsz = single(regs.GNRL.imgVsize);
% Hsz = single(regs.GNRL.imgHsize);
% 
% 
% % Note - marginB refers to margin taken for y == 0. marginT is the margin
% % for y == imVsize-1. Therefore, marginB should be calculated by the margin
% % at the top of the image, and marginT should be calculated by the margin
% % at the bottom of the image - as pixel 0 is on top and pixel 479 is at the
% % bottom. 
% roiregs.FRMW.marginB = int16((-B*Vsz + T*B*Vsz/(T-Vsz)) / (B-Vsz-T*B/(T-Vsz)));
% roiregs.FRMW.marginT = int16((-T*Vsz + T*B*Vsz/(B-Vsz)) / (T-Vsz-T*B/(B-Vsz)));
% roiregs.FRMW.marginL = int16((-L*Hsz + L*R*Hsz/(R-Hsz)) / (L-Hsz-L*R/(R-Hsz)));
% roiregs.FRMW.marginR = int16((-R*Hsz + L*R*Hsz/(L-Hsz)) / (R-Hsz-L*R/(L-Hsz)));
% 
% 


end
