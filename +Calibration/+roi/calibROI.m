function [roiregs] = calibROI( imU,imD,regs,calibParams)
% Calibrate the margins of the image.
% 1. Take a spherical mode image of up direction.
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
edgesU = calcBounds(imU);
marginsU = calcMargins(edgesU,regs,calibParams);
edgesD = calcBounds(imD);
marginsD = calcMargins(edgesD,regs,calibParams);

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
function edges = calcBounds(im)
%% Mark desired pixels on spherical image
% Todo - in any case, do not allow the bound toslice into the real image.

binaryIm = im > 0;
[binaryIm,stats] = maxAreaStat(binaryIm,size(im));% Keep only the largest connected component.
im(~binaryIm) = 0;
leftCol = ceil(stats.BoundingBox(1));
rightCol = min(leftCol+stats.BoundingBox(3),size(im,2));

% Use the 3 outermost columns for nest estimation
noiseValues = im(:,[leftCol:leftCol+2,rightCol-2:rightCol]);
noiseThresh = max(noiseValues(noiseValues>0));

% Find noise pixels
noiseIm = (im > 0) .* (im <= noiseThresh);
notNoiseIm = im > noiseThresh;
noiseColumns = (sum(noiseIm)>0) .*  (sum(notNoiseIm)==0);

% Find the right and left margins - index of the pixels that bound the
% image without the noise.
leftImIndex = find(diff(noiseColumns)==-1,1,'first')+1;
rightImIndex = find(diff(noiseColumns)==1,1,'last');

% The top noise strip of the image is diagonal. Find the pixel where the noise stops for each column.
noiseStartRowPerCol = arrayfun(@(x) find(binaryIm(:,x)>0,1,'first'), leftImIndex:rightImIndex);
noiseEndRowPerCol = arrayfun(@(x) find(binaryIm(:,x)>0,1,'last'), leftImIndex:rightImIndex);
notNoiseStartRowPerCol = arrayfun(@(x) find(notNoiseIm(:,x)>0,1,'first'), leftImIndex:rightImIndex);
notNoiseEndRowPerCol = arrayfun(@(x) find(notNoiseIm(:,x)>0,1,'last'), leftImIndex:rightImIndex);

topWidth = median(notNoiseStartRowPerCol - noiseStartRowPerCol);
bottomWidth = median(noiseEndRowPerCol-notNoiseEndRowPerCol);

topEdge = [min(noiseStartRowPerCol+topWidth,notNoiseStartRowPerCol)',(leftImIndex:rightImIndex)']; 
bottomEdge = [max(noiseEndRowPerCol-bottomWidth,notNoiseEndRowPerCol)',(leftImIndex:rightImIndex)']; 
leftEdge = (topEdge(1,1):bottomEdge(1,1))'; leftEdge = [leftEdge,leftImIndex*ones(size(leftEdge))];
rightEdge = ((topEdge(end,1)):(bottomEdge(end,1)))'; rightEdge = [rightEdge,rightImIndex*ones(size(rightEdge))];
% imageFrame = [topEdge; rightEdge; flipud(bottomEdge); flipud(leftEdge)];% Add left column

% figure; imagesc(im); hold on; plot(imageFrame(:,2),imageFrame(:,1),'r','linewidth',2);

edges.T = topEdge;
edges.B = bottomEdge;
edges.L = leftEdge;
edges.R = rightEdge;

end
function marginsTBLR = calcMargins(edges,regs,calibParams)
ang2xy = @(sphericalPixels) spherical2xy(sphericalPixels,regs,calibParams); 
edgesXY = structfun(ang2xy,edges,'UniformOutput',false); 
marginsTBLR(1) = ceil(max(edgesXY.T(:,2)));
marginsTBLR(2) = single(regs.GNRL.imgVsize) - floor(min(edgesXY.B(:,2)));
marginsTBLR(3) = ceil(max(edgesXY.L(:,1)));
marginsTBLR(4) = single(regs.GNRL.imgHsize) - floor(min(edgesXY.R(:,1)));
end
function xy = spherical2xy(sphericalPixels,regs,calibParams)
% angX/angY is translated to xyz using the regs and fov expander model if
% it exists.
% Then the xyz is translated to te cordinate in the image plane. If a fov
% expander model is valid, 
        yy = double(sphericalPixels(:,1));
        xx = double(sphericalPixels(:,2)*4);
        xx = xx-double(regs.DIGG.sphericalOffset(1));
        yy = yy-double(regs.DIGG.sphericalOffset(2));
        xx = xx*2^10;%bitshift(xx,+12-2);
        yy = yy*2^12;%bitshift(yy,+12);
        xx = xx/double(regs.DIGG.sphericalScale(1));
        yy = yy/double(regs.DIGG.sphericalScale(2));
        angx = single(xx);
        angy = single(yy);
        if calibParams.fovExpander.valid
            FE = calibParams.fovExpander.table;
            oXYZ = Calibration.aux.ang2vec(angx,angy,regs,FE)';
            imaginaryRegs = regs;
            imaginaryRegs.FRMW.xfov = interp1(FE(:,1),FE(:,2),regs.FRMW.xfov/2)*2;
            imaginaryRegs.FRMW.yfov = interp1(FE(:,1),FE(:,2),regs.FRMW.yfov/2)*2;    
            [x,y] = vec2xy(oXYZ',imaginaryRegs);
            x = x'; y = y';
        else
            [x,y] = Calibration.aux.ang2xySF(angx,angy,regs,[],1);
        end
        xy = [x,y];
end
function roiregs = margins2regs(margins,regs)
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
% rB = (-B*Vsz + T*B*Vsz/(T-Vsz)) / (B-Vsz-T*B/(T-Vsz));
T = margins(1); B = margins(2);
L = margins(3); R = margins(4);
Vsz = single(regs.GNRL.imgVsize);
Hsz = single(regs.GNRL.imgHsize);

roiregs.FRMW.marginT = int16((-T*Vsz + T*B*Vsz/(B-Vsz)) / (T-Vsz-T*B/(B-Vsz)));
roiregs.FRMW.marginB = int16((-B*Vsz + T*B*Vsz/(T-Vsz)) / (B-Vsz-T*B/(T-Vsz)));
roiregs.FRMW.marginL = int16((-L*Hsz + L*R*Hsz/(R-Hsz)) / (L-Hsz-L*R/(R-Hsz)));
roiregs.FRMW.marginR = int16((-R*Hsz + L*R*Hsz/(L-Hsz)) / (R-Hsz-L*R/(L-Hsz)));




end
function [ xF,yF ] = vec2xy( oXYZ,regs)
xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
rangeR = xyz2nrmxy(oXYZfunc(angles2xyz( regs.FRMW.xfov*0.25,                   0)));rangeR=rangeR(1);
rangeL = xyz2nrmxy(oXYZfunc(angles2xyz(-regs.FRMW.xfov*0.25,                   0)));rangeL=rangeL(1);
rangeT = xyz2nrmxy(oXYZfunc(angles2xyz(0                   , regs.FRMW.yfov*0.25)));rangeT =rangeT (2);
rangeB = xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-regs.FRMW.yfov*0.25)));rangeB=rangeB(2);

guardXinc = regs.FRMW.guardBandH*single(regs.FRMW.xres);
guardYinc = regs.FRMW.guardBandV*single(regs.FRMW.yres);

xresN = single(regs.FRMW.xres) + guardXinc*2;
yresN = single(regs.FRMW.yres) + guardYinc*2;

xy00 = [rangeL;rangeB];
xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];% xys = [xresN-1;yresN-1]./[rangeR-rangeL;rangeT-rangeB];
xynrm = [xyz2nrmx(oXYZ);xyz2nrmy(oXYZ)];
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);
marginT = regs.FRMW.marginT;
marginL = regs.FRMW.marginL;
xy = bsxfun(@minus,xy,double([marginL+int16(guardXinc);marginT+int16(guardYinc)]));

xF = xy(1,:);
yF = xy(2,:);
end