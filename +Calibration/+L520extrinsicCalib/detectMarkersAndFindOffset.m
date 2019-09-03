function [targetOffset] = detectMarkersAndFindOffset(calibParams,InRawdata,detectedPointData)
%% Input data
IRimage=InRawdata.Frames(1).i;
zImage=InRawdata.Frames(1).z;
CamParam=InRawdata.params;
detectedGridPointsV=detectedPointData.detectedGridPointsV;


%% find marker
maxMarkersNum=calibParams.target.markersNumPerColor;
% estimate radius range
[rminPix,rmaxPix] =estimateCirRadRange(calibParams,detectedPointData);

% initial search with Hough transform
fltr4accum = [1 2 1; 2 6 2; 1 2 1];
fltr4accum = fltr4accum / sum(fltr4accum(:));
[accum, initcircen, initcirrad] = Calibration.aux.CircularHough_Grd(double(IRimage), [rminPix rmaxPix],10, 4, 0.5, fltr4accum);

% remove detected circels out of CB grid
[initcircen,initcirrad]=removeCirOutOfBoard(detectedPointData.cbXmargin,detectedPointData.cbYmargin,initcircen,initcirrad);

idx=sub2ind(size(accum),round(initcircen(:,2)),round(initcircen(:,1)));
% figure(); imagesc(IRimage); hold on;viscircles(initcircen,initcirrad)
% figure(); imagesc(accum);
accumCir=accum(idx);
[~ , sortedInds]=sort(accumCir,'descend');
PotentialCirInd=sortedInds(1:maxMarkersNum);
PotcirCen=initcircen(PotentialCirInd,:);
PotcirCenV=Validation.aux.pointsToVertices(PotcirCen-1,zImage,CamParam);
r=mean(initcirrad(PotentialCirInd));

bestOptCenV=PotcirCenV(1,:);
cirCen=PotcirCen(1,:);
for(i=2:maxMarkersNum)
    cirdx=abs(bestOptCenV(1,1)-PotcirCenV(i,1));
    cirdy=abs(bestOptCenV(1,2)-PotcirCenV(i,2));
    if(cirdx<calibParams.target.cbSquareSz && cirdy<calibParams.target.cbSquareSz)
        cirCen=[cirCen ; PotcirCen(i,:)];
    end
end

markerNum=size(cirCen,1);
if(calibParams.gnrl.verbose)
    h=figure(); imagesc(IRimage); hold on;
    viscircles(cirCen,r*ones(markerNum,1));title('detected marker');
    saveas(h,strcat(InRawdata.outPath,'\detectedMarker.png'));
end
markerCenter=mean(cirCen);
markerCenterV=Validation.aux.pointsToVertices(markerCenter-1,zImage,CamParam);
%% detect marker color
[isBlack]=detectMarkerColor(double(IRimage),cirCen(1,:) );
%% calculate offset
gridOrigin=detectedGridPointsV(1,:);
% dy = horizontal offset due to rot90
dy=(gridOrigin(1)-markerCenterV(1))/calibParams.target.cbSquareSz; dy=-sign(dy)*ceil(abs(dy));
dx=(gridOrigin(2)-markerCenterV(2))/calibParams.target.cbSquareSz; dx=sign(dx)*floor(abs(dx));
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
if(calibParams.gnrl.verbose)
    h=figure(); imagesc(imrotate(IRimage,90)); hold on;
    [rotpoint]=rot90Point(IRimage,detectedPointData.CBorig);
    scatter(rotpoint(1),rotpoint(2),'+','MarkerEdgeColor','r','LineWidth',1.5);
    title(strcat('orig to marker in world is: dx=', num2str(dx), 'sq  dy=',num2str(dy),'sq'));
    saveas(h,strcat(InRawdata.outPath,'\offsetRes.png'));
end
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
ix=find(initcircen(:,1)<CBxmargin(1) | initcircen(:,1)>CBxmargin(2) );
if(~isempty(ix))
    initcircen(ix,:)=[];
    initcirrad(ix,:)=[];
end
iy=find(initcircen(:,2)<CBymargin(1) | initcircen(:,2)>CBymargin(2));
if(~isempty(iy))
    initcircen(iy,:)=[];
    initcirrad(iy,:)=[];
end

end

function [rminPix,rmaxPix] =estimateCirRadRange(calibParams,detectedPointData)
cirRad_mm=calibParams.target.circleRad_mm;
RtoSqRatio=cirRad_mm/calibParams.target.cbSquareSz;
rminPix=max(floor(RtoSqRatio*min(detectedPointData.HrecRange(1), detectedPointData.VrecRange(1))),1);
rmaxPix=ceil(RtoSqRatio*max(detectedPointData.HrecRange(2), detectedPointData.VrecRange(2)));
end