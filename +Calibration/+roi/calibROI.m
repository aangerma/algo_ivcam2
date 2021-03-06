function [roiregs] = calibROI( imU,imD,imNoise,regs,calibParams,runParams)
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

noiseThresh = max(imNoise(:));
noiseThresh = noiseThresh*calibParams.roi.noiseMarginFactor;
%% Get margins for each image
edgesU = calcBounds(imU,noiseThresh,runParams,regs,'imU');
marginsU = calcMargins(edgesU,regs,runParams);
edgesD = calcBounds(imD,noiseThresh,runParams,regs,'imD');
marginsD = calcMargins(edgesD,regs,runParams);

% As weird as it is, extra margins are consistent with FRMWmargin*.
% Therefore Top is actually the bottom of the image (in hw.getFrame),
% Bottom is the top, left is left and right is right. Frame from
% hw.getFrame are rotated by 180 from the real world. Bottom <-> Top
% confusion should be fixed. 

extraMargins = [calibParams.roi.extraMarginT,...
                calibParams.roi.extraMarginB,...
                calibParams.roi.extraMarginL,...
                calibParams.roi.extraMarginR]*calibParams.roi.useExtraMargins;
margins = max([marginsU;marginsD])+extraMargins;
roiregs = margins2regs(margins,regs);

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
function edges = calcBounds(im,noiseThresh,runParams,regs,description)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.

binaryIm = im > 0;
[binaryIm,stats] = maxAreaStat(binaryIm,size(im));% Keep only the largest connected component.
im(~binaryIm) = 0;

% Find noise pixels
noiseIm = (im > 0) .* (im <= noiseThresh);
notNoiseIm = im > noiseThresh;
noiseColumns = (sum(noiseIm)>0) .*  (sum(notNoiseIm)==0);

% Find the corners of the not noise image - connect them
[xi,yi] = meshgrid(1:size(im,2),1:size(im,1));
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
imagesc(im); hold on; plot(imageFrame(:,2),imageFrame(:,1),'r','linewidth',2);
title(description);
Calibration.aux.saveFigureAsImage(ff,runParams,'ROI',description)

edges.T = topEdge;
edges.B = bottomEdge;
edges.L = leftEdge;
edges.R = rightEdge;

end
function xyClose = closest2pointL1(xy,p)
    [~,Imin] = min(sum(abs(double(xy)-double(p)),2));
    xyClose = xy(Imin,:);
end
function marginsTBLR = calcMargins(edges,regs,runParams)
if exist(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat'), 'file') == 2
    load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); % loads undistTpsModel
else
    tpsUndistModel = [];
end

ang2xy = @(sphericalPixels) spherical2xy(sphericalPixels,regs,tpsUndistModel); 
edgesXY = structfun(ang2xy,edges,'UniformOutput',false); 
factor = 0.80;
marginsTBLR(1) = ceil(max(edgesXY.T(innerIndices(edgesXY.T,factor),2)));
marginsTBLR(2) = single(regs.GNRL.imgVsize) - floor(min(edgesXY.B(innerIndices(edgesXY.B,factor),2)));
marginsTBLR(3) = ceil(max(edgesXY.L(innerIndices(edgesXY.L,factor),1)));
marginsTBLR(4) = single(regs.GNRL.imgHsize) - floor(min(edgesXY.R(innerIndices(edgesXY.R,factor),1)));

marginsTBLR(1:2) = marginsTBLR([2,1]); % marginT actually refers to the bottom of the image and vice versa (names should be swapped)
end
function plotEdges()
    figure,
    plot(edgesXY.T(:,1),edgesXY.T(:,2),'linewidth',2),hold on
    plot(edgesXY.B(:,1),edgesXY.B(:,2),'linewidth',2),hold on
    plot(edgesXY.L(:,1),edgesXY.L(:,2),'linewidth',2),hold on
    plot(edgesXY.R(:,1),edgesXY.R(:,2),'linewidth',2),hold on
    rectangle('Position',[0,0,640,480],'linewidth',2)
end
function ind = innerIndices(v,factor)
% Return the indices of the inner factor percent of vector rows
vlen = size(v,1);
allInd = 1:vlen;
ind = allInd(uint16(vlen*(1-factor)/2) :uint16(vlen*(1+factor)/2));
end
function xy = spherical2xy(sphericalPixels,regs,tpsUndistModel)
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
        % (To add) 2D Undist - 
        % v = Calibration.Undist.undistByTPSModel( v,[],runParams );
        xy = [x,y];
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
