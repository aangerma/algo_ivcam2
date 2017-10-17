function tilesMetric(projStruct,f)

%%

[fidPlacesOrig, xyCornersOrig] = getXYcorners();
fidPlacesOrig = fidPlacesOrig- fidPlacesOrig(1,:);

fidProjPlaces = projStruct.fidProjPlaces;
fidProjPlaces = fidProjPlaces - fidProjPlaces(1,:);

xRatio = fidProjPlaces(2,1)/fidPlacesOrig(2,1);
yRatio = fidProjPlaces(4,2)/fidPlacesOrig(4,2);

xyCornersTight = [xyCornersOrig(:,1)*xRatio xyCornersOrig(:,2)*yRatio];



%% normalize the image
ROI_SZ = 50;

Imn = imerode(projStruct.Iproj,ones(ROI_SZ)); %find lowest value for each fixel in N size area
Imx = imdilate(projStruct.Iproj,ones(ROI_SZ));%find highest value for each fixel in N size area

In = (projStruct.Iproj-Imn)./(Imx-Imn);
In(isnan(In))=0;
if(0)
    %%
    figure(5721);imagesc(In);axis image
    drawnow;
    colormap gray
end

Inorm = single(In);



%% find xy corners:
%conv with tile tamplateand then take peaks erea.
%each erea is a connected componentand then we can find the absolut peak.
tile = ones(ceil(ROI_SZ/2));
tilesTamplate = [tile -tile; -tile tile];




MARGIN = ceil((max(fidProjPlaces(:))-min(fidProjPlaces(:)))/15);
[xroi,yroi] = meshgrid(   ((min(fidProjPlaces(:,1))-MARGIN) : (max(fidProjPlaces(:,1)))+MARGIN)-projStruct.x0(1) ,  ((min(fidProjPlaces(:,2))-MARGIN) : (max(fidProjPlaces(:,2)))+MARGIN)-projStruct.x0(2));
Iroi = reshape(Inorm(    sub2ind(size(Inorm),yroi(:),xroi(:))   ),  size(xroi)  );
x0ROI = [min(xroi(:))-1 min(yroi(:))-1];

tilesConv = abs(conv2(Iroi,tilesTamplate,'same'));


CC.NumObjects = 0;
prcConst = 99.99;
while(CC.NumObjects< size(xyCornersOrig,1))
    prcConst = prcConst-0.01;
    
    PEAK_CONV_VALUE = prctile(tilesConv(:),prcConst);
    tileSconvMask =  tilesConv>PEAK_CONV_VALUE;
    
    CC = bwconncomp(tileSconvMask);
    
    if(0)
        L = labelmatrix(CC);
        figure(32443);clf;imagesc(L);title(num2str(CC.NumObjects));pause(0.1)
    end
end
L = labelmatrix(CC);

if(0)
    %%
    figure
    imagesc(imfuse(tilesConv,(label2rgb(L))));
end

% get the max ind for each cc
cornerInd = zeros(CC.NumObjects,1);
for i=1:CC.NumObjects
    tilesCC = zeros(size(tilesConv));
    tilesCC(L(:)==i) = tilesConv(L(:)==i);
    tmpMaxInd = maxind(tilesCC(:));
    
    cornerInd(i) = tmpMaxInd;
    
end




%% sort the point so that each point is in order as original points
[y,x] = ind2sub(size(tilesConv),cornerInd);
x = x+projStruct.x0(1)+x0ROI(1);y = y+projStruct.x0(2)+x0ROI(2);

if(0)
    %%
    figure(245214);clf
    [xTrans,yTrans] = meshgrid(projStruct.x0(1):(size(projStruct.Iproj,2)+projStruct.x0(1)-1),projStruct.x0(2):(size(projStruct.Iproj,1)+projStruct.x0(2)-1));
    imagesc(xTrans(:),yTrans(:),projStruct.Iproj);axis image;colormap gray;
    hold on;
    plot(x,y,'*');
end

IDX = kmeans(y , 15);

meanY = zeros(15,1);
for i=1:15
    meanY(i) = mean(y(IDX==i));
end

[~,sortedInd] = sort(meanY);

xFinal = [];
yFinal = [];

for i=1:15
    
    xx = x(IDX==sortedInd(i));
    yy = y(IDX==sortedInd(i));
    
    [xxx,xxxInd] = sort(xx);
    yyy = yy(xxxInd);
    
    xFinal = [xFinal; xxx];
    yFinal = [yFinal; yyy];
end



if(0)
    %%
    figure;hold on
    plot(xyCornersTight(:,1),xyCornersTight(:,2),'*b');
    text(   xyCornersTight(:,1),xyCornersTight(:,2),num2str((1:length(xyCornersTight(:,1)))')  )
    
    plot(xFinal,yFinal,'*g')
    text(   xFinal,yFinal,num2str(((1:length(yFinal)))')  )
end



%% plot results

[xTrans,yTrans] = meshgrid(projStruct.x0(1):(size(projStruct.Iproj,2)+projStruct.x0(1)-1),projStruct.x0(2):(size(projStruct.Iproj,1)+projStruct.x0(2)-1));

figure(f);
tabplot();
subplot(121)
imagesc(xTrans(:),yTrans(:),projStruct.Iproj);axis image;colormap gray;hold on;
plot(xFinal,yFinal,'*g')
plot(xyCornersTight(:,1),xyCornersTight(:,2),'*b')
title('overlay on projected image')
legend('extracted points','original position')


subplot(122)
h = quiver(xyCornersTight(:,1),xyCornersTight(:,2),xFinal-xyCornersTight(:,1),yFinal-xyCornersTight(:,2));

% h.AutoScaleFactor

title('quiver plot of points movement- not to scale!')
set(gca,'Ydir','reverse')
end




function [fidPlaces, xyCorners] = getXYcorners()
%corner places in [cm] compared to center of upper left fiducial at (0,0)-
%inkscape lengths...
fidPlaces = [...
    0 0;
    60.8 0;
    60.8 41.6;
    0 41.6];

xyCorners = [...
    27.2 -1.6;
    30.4 -1.6;
    33.6 -1.6;
    36.8 -1.6;
    40 -1.6;
    27.2 1.6;
    30.4 1.6;
    33.6 1.6;
    36.8 1.6;
    40 1.6;
    27.2 4.8;
    30.4 4.8;
    33.6 4.8;
    36.8 4.8;
    40 4.8;
    27.2 8;
    30.4 8;
    33.6 8;
    36.8 8;
    40 8;
    43.2 8;
    24 11.2;
    40 11.2;
    43.2 11.2;
    46.4 11.2;
    11.2 14.4;
    14.4 14.4;
    17.6 14.4;
    20.8 14.4;
    43.2 14.4;
    46.4 14.4;
    11.2 17.6;
    14.4 17.6;
    17.6 17.6;
    43.2 17.6;
    46.4 17.6;
    11.2 20.8;
    14.4 20.8;
    17.6 20.8;
    43.2 20.8;
    46.4 20.8;
    49.6 20.8;
    14.4 24;
    17.6 24;
    43.2 24;
    46.4 24;
    49.6 24;
    14.4 27.2;
    17.6 27.2;
    40 27.2;
    43.2 27.2;
    46.4 27.2;
    49.6 27.2;
    14.4 30.4;
    17.6 30.4;
    20.8 30.4;
    36.8 30.4;
    17.6 33.6;
    20.8 33.6;
    24 33.6;
    27.2 33.6;
    30.4 33.6;
    33.6 33.6;
    20.8 36.8;
    24 36.8;
    27.2 36.8;
    30.4 36.8;
    33.6 36.8;
    20.8 40;
    24 40;
    27.2 40;
    30.4 40;
    33.6 40;
    20.8 43.2;
    24 43.2;
    27.2 43.2;
    30.4 43.2;
    33.6 43.2];
end