function [roseCurves, cubesIdata,cubesZdata] = irMetrics(I,Z,f)
%find metrics on the IR calibration target


if(nargin==1)
    Z = [];
end
if(nargin<3)
    f = figure('name','calibration target results');
end

I = double(I);



%% fill small holes in image - 5X5 region
Ib = I(Utils.indx2col(size(I),[5 5]));
bd = Ib(13,:)==0;
Ib(13,bd)=median(Ib([1:12 14:end],bd));
I = reshape(Ib(13,:),size(I));


%% get fiducials
piducialCenter = Calibration.verifTarget.find4fiducials(I);

if(0)
    %%
    figure(87696);
    tabplot();
    imagesc(I);axis image;colormap gray;hold on;
    for i=1:4
        plot(piducialCenter(i,1),piducialCenter(i,2),'*','lineWidth',5);
        text(piducialCenter(i,1),piducialCenter(i,2),num2str(i))
    end
    title('fiducials center');
    drawnow;
end


%% project to rectangle
FIDUCIAL_DIST_W = 33.5; FIDUCIAL_DIST_H = 23.3;

projStruct.fidProjPlaces = [...
    0 0;
    FIDUCIAL_DIST_W 0;
    FIDUCIAL_DIST_W FIDUCIAL_DIST_H;
    0 FIDUCIAL_DIST_H]*40;

projStruct.Hproj = Calibration.verifTarget.getHomogenicProjectionMatrix( piducialCenter, projStruct.fidProjPlaces );

[projStruct.Iproj,projStruct.x0] = Calibration.verifTarget.invWarp(I,projStruct.Hproj,projStruct.fidProjPlaces);

if(~isempty(Z))
    projStruct.Zproj = Calibration.verifTarget.invWarp(Z,projStruct.Hproj,projStruct.fidProjPlaces);
else
    projStruct.Zproj = [];
end

figure(f);
maximize(f)
tabplot();
subplot(121);
imagesc(I);axis image;colormap gray;
title('original image')
subplot(122);
[xTrans,yTrans] = meshgrid(projStruct.x0(1):(size(projStruct.Iproj,2)+projStruct.x0(1)-1),projStruct.x0(2):(size(projStruct.Iproj,1)+projStruct.x0(2)-1));
imagesc(xTrans(:),yTrans(:),projStruct.Iproj);axis image;colormap gray;
title('projected image')


if(1)
    %% get roses
    roseCurves = Calibration.verifTarget.allRosesSummery(I,projStruct,f);
        
    %% 3X3 qubes gray level
    [cubesIdata,cubesZdata] = Calibration.verifTarget.grayLevelMetric(I,Z,projStruct,f);
end

%% find tile corners
Calibration.verifTarget.tilesMetric(projStruct,f);

end