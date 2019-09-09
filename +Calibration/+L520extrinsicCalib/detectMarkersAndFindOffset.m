function [targetOffset] = detectMarkersAndFindOffset(calibParams,InRawdata,CBData)
%% Input data
IRimage=InRawdata.Frames(1).i;
zImage=InRawdata.Frames(1).z;
CamParam=InRawdata.params;
detectedGridPointsV=CBData.vert';

[CBrecRangesize.HrecRange,CBrecRangesize.VrecRange,cbXmargin,cbYmargin]= calculateCheckersRecRangeSizePix(CBData);

%% find marker
maxMarkersNum=calibParams.target.markersNumPerColor;
% estimate radius range
[rminPix,rmaxPix] =estimateCirRadRange(calibParams,CBrecRangesize);

% initial search with Hough transform
fltr4accum = [1 2 1; 2 6 2; 1 2 1];
fltr4accum = fltr4accum / sum(fltr4accum(:));
[accum, initcircen, initcirrad] = Calibration.aux.CircularHough_Grd(double(IRimage), [rminPix rmaxPix],5, 4, 0.5, fltr4accum);

% remove detected circels out of CB grid
[initcircen,initcirrad]=removeCirOutOfBoard(cbXmargin,cbYmargin,initcircen,initcirrad);

idx=sub2ind(size(accum),round(initcircen(:,2)),round(initcircen(:,1)));
% figure(); imagesc(IRimage); hold on;viscircles(initcircen,initcirrad)
% figure(); imagesc(accum);
accumCir=accum(idx);

[~ , sortedInds]=sort(accumCir,'descend');
PotentialCirInd=sortedInds(1:min(maxMarkersNum,length(sortedInds)));
PotcirCen=initcircen(PotentialCirInd,:);
PotcirCenV=Validation.aux.pointsToVertices(PotcirCen-1,zImage,CamParam);
r=mean(initcirrad(PotentialCirInd));

%% isolate circles in single marker
bestOptCenV=PotcirCenV(1,:);
cirCen=PotcirCen(1,:);
for(ii=2:min(maxMarkersNum,length(sortedInds)))
    cirdx=abs(bestOptCenV(1,1)-PotcirCenV(ii,1));
    cirdy=abs(bestOptCenV(1,2)-PotcirCenV(ii,2));
    if(cirdx<calibParams.target.cbSquareSz && cirdy<calibParams.target.cbSquareSz)
        cirCen=[cirCen ; PotcirCen(ii,:)];
    end
end

markerNum=size(cirCen,1);
if(calibParams.gnrl.verbose)
    h=figure(); imagesc(IRimage); hold on;
    viscircles(cirCen,r*ones(markerNum,1));title('detected marker');
    saveas(h,strcat(InRawdata.outPath,'\detectedMarker.png'));
end
markerCenter=mean(cirCen);
%% detect marker color
[isBlack]=detectMarkerColor(double(IRimage),cirCen(1,:) );

%% calculate offset
% calculate from detected grid
[dx,dy,rotCenter]=calc_dxdy_fromCBgrid(IRimage,markerCenter,CBData); 

% calculate from point cloud
% [dx_,dy_]=calc_dxdy_fromPointCloud(detectedGridPointsV,markerCenter,zImage,calibParams,CamParam) 

if isBlack
    x0=calibParams.target.blackMarkers.horizontalCBoffset;
    y0=calibParams.target.blackMarkers.verticalCBoffset;
else
    x0=calibParams.target.whiteMarkers.horizontalCBoffset;
    y0=calibParams.target.whiteMarkers.verticalCBoffset;
end
markerSpace=calibParams.target.markerSpace;
targetOffset.offX=x0+(markerNum-1)*markerSpace+(markerNum-1)+dx;
targetOffset.offY=y0+dy;

%% vis
CBorig=CBData.gridPoints(1,:);
if(calibParams.gnrl.verbose)
    h=figure(); imagesc(imrotate(IRimage,90)); hold on;
    [rotpoint]=rot90Point(IRimage,CBorig);
    scatter(rotpoint(1),rotpoint(2),'+','MarkerEdgeColor','r','LineWidth',1.5);
    scatter(rotCenter(1),rotCenter(2),'o','MarkerEdgeColor','r','LineWidth',1.5);
    title(strcat('orig to marker in world is: dx=', num2str(dx), 'sq  dy=',num2str(dy),'sq'));
    saveas(h,strcat(InRawdata.outPath,'\offsetRes.png'));
end
end

function [dx,dy,rotCenter]=calc_dxdy_fromCBgrid(IRimage,markerCenter,CBData)
rotCenter=rot90Point(IRimage,markerCenter);
rotatedGrid=rot90Point(IRimage,CBData.gridPoints)';
x=rotatedGrid(:,1); y=rotatedGrid(:,2); 

X=flipud(reshape(x,CBData.gridSize)'); Y=flipud(reshape(y,CBData.gridSize)');
colsAve=mean(X,1); 
rowsAve=mean(Y,2); 
dx=-(sum((rotCenter(1)>colsAve))-1); 
dy=sum((rotCenter(2)<rowsAve)); 
end 

function [dx,dy]=calc_dxdy_fromPointCloud(detectedGridPointsV,markerCenter,zImage,calibParams,CamParam)
markerCenterV=Validation.aux.pointsToVertices(markerCenter-1,zImage,CamParam);
gridOrigin=detectedGridPointsV(1,:);
% dy = horizontal offset due to rot90
dy=(gridOrigin(1)-markerCenterV(1))/calibParams.target.cbSquareSz; dy=-sign(dy)*ceil(abs(dy));
dx=(gridOrigin(2)-markerCenterV(2))/calibParams.target.cbSquareSz; dx=sign(dx)*floor(abs(dx));
end
function [rotpoint]=rot90Point(origIm,origP)
theta=90;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
imCenter=fliplr(size(origIm)/2);
rotpoint = [1 -1]'.*(R*([1 -1].*origP+[-1 1].*imCenter)')+fliplr(imCenter)';
end

function [isBlack]=detectMarkerColor(IrImage,circleCen )
whiteVal=max(IrImage(:));
blackVal=min(IrImage(:));
inds=fliplr(round(circleCen));
cirVal=IrImage(inds(1),inds(2));
if(abs(cirVal-blackVal)<abs(cirVal-whiteVal))
    isBlack=1 ;
else
    isBlack=0;
end
end

function [initcircen,initcirrad]=removeCirOutOfBoard(CBxmargin,CBymargin,initcircen,initcirrad)
in = inpolygon(initcircen(:,1),initcircen(:,2),CBxmargin,CBymargin); 
initcircen(~in,:)=[]; 
initcirrad(~in)=[]; 

end

function [rminPix,rmaxPix] =estimateCirRadRange(calibParams,CBrecRangesize)
cirRad_mm=calibParams.target.circleRad_mm;
RtoSqRatio=cirRad_mm/calibParams.target.cbSquareSz;
rminPix=max(floor(RtoSqRatio*min(CBrecRangesize.HrecRange(1), CBrecRangesize.VrecRange(1))),1);
rmaxPix=ceil(RtoSqRatio*max(CBrecRangesize.HrecRange(2), CBrecRangesize.VrecRange(2)));
end


function[HrecRange,VrecRange,cbXmargin,cbYmargin]= calculateCheckersRecRangeSizePix(camsAnalysis)
x=camsAnalysis.gridPoints(:,1); y=camsAnalysis.gridPoints(:,2);
X=reshape(x,camsAnalysis.gridSize); Y=reshape(y,camsAnalysis.gridSize);
dx=mean(diff(X'));
HrecRange=[min(dx), max(dx)];
dy=mean(diff(Y)');
VrecRange=[min(dy), max(dy)];
cbXmargin=[X(1,1) ; X(end,1) ;  X(end,end) ;  X(1,end)];
cbYmargin=[Y(1,1) ; Y(end,1) ;  Y(end,end) ;  Y(1,end)];

end
