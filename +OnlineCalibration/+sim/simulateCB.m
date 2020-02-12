%% Assuming The CB is at 0.5m, and every CB size in mm is 30mm, how will it look at the IR image
backgroundDimsMm = [3000,5000];
backgroundDist = 2000;
cbDist = 500;
squareSz = 30;
color = I;
resRgb = [1080,1920];
res = [480,640];
kDepth = [456.6904         0  328.3080
         0  457.1310  247.2648
         0         0    1.0000];
Krgb = [1346.03857421875,0,978.718750000000;0,1345.64758300781,560.761718750000;0,0,1];
rgbPMat = [1365.7192,4.8422594,951.05103,-6183.5063;-11.557178,1334.4147,586.87732,14870.460;0.020603323,-0.019217802,0.99960303,-7.0072355];
distortionParams = [0.1332   -0.4466    0.0002    0.0002    0.4030];     
     
I = imread('X:\Data\IvCam2\OnlineCalibration\Simulator\CB.jpg');
I(I == 0) = 0.1;
B = imread('X:\Data\IvCam2\OnlineCalibration\Simulator\background.jpg');
B = imresize(B,res);
Bgs = rgb2gray(B);

     
[xg,yg] = meshgrid(1:res(2),1:res(1));
[xgRgb,ygRgb] = meshgrid(1:resRgb(2),1:resRgb(1));

% Project CB to depth image
xySzMm = squareSz*(cbGridSz+1);
xLoc = linspace(-xySzMm(2)/2,xySzMm(2)/2,size(I,2));
yLoc = linspace(-xySzMm(1)/2,xySzMm(1)/2,size(I,1));
[grX,grY] = meshgrid(xLoc,yLoc);
verticesCB = [grX(:),grY(:),cbDist*ones(size(grY(:)))];
projVerts = verticesCB*(kDepth');
xF =  projVerts(:,1)./projVerts(:,3)+1;
yF =  projVerts(:,2)./projVerts(:,3)+1;
frameCB.z = griddata(double(xF),double(yF),double(vertices(:,3)),double(xg),double(yg));
frameCB.i = griddata(double(xF),double(yF),double(I(:)),double(xg),double(yg));

% Project Background to depth image
xLoc = linspace(-backgroundDimsMm(2)/2,backgroundDimsMm(2)/2,size(Bgs,2));
yLoc = linspace(-backgroundDimsMm(1)/2,backgroundDimsMm(1)/2,size(Bgs,1));
[grX,grY] = meshgrid(xLoc,yLoc);
verticesBG = [grX(:),grY(:),backgroundDist*ones(size(grY(:)))];
projVerts = verticesBG*(kDepth');
xF =  projVerts(:,1)./projVerts(:,3)+1;
yF =  projVerts(:,2)./projVerts(:,3)+1;
frameBgnd.z = griddata(double(xF),double(yF),double(vertices(:,3)),double(xg),double(yg));
frameBgnd.i = griddata(double(xF),double(yF),double(Bgs(:)),double(xg),double(yg));

%% Join the depth frame
frame.z = frameBgnd.z;
frame.z(frameCB.z>0) = frameCB.z(frameCB.z>0);
frame.i = frameBgnd.i;
frame.i(frameCB.z>0) = frameCB.i(frameCB.z>0);



%% Project to rgb image
VEx = [verticesCB,ones(size(verticesCB,1),1)];
projVerts = VEx*(rgbPMat');
u = (projVerts(:,1)./projVerts(:,3));
v = (projVerts(:,2)./projVerts(:,3));
uvMap = [u,v];
uvMapUndist = du.math.distortCam(uvMap', Krgb, distortionParams)' + 1;
rgbCBIm = griddata(double(uvMapUndist(:,1)),double(uvMapUndist(:,2)),double(I(:)),double(xgRgb),double(ygRgb));


VEx = [verticesBG,ones(size(verticesBG,1),1)];
projVerts = VEx*(rgbPMat');
u = (projVerts(:,1)./projVerts(:,3));
v = (projVerts(:,2)./projVerts(:,3));
uvMap = [u,v];
uvMapUndist = du.math.distortCam(uvMap', Krgb, distortionParams)' + 1;
rgbBgndIm = griddata(double(uvMapUndist(:,1)),double(uvMapUndist(:,2)),double(Bgs(:)),double(xgRgb),double(ygRgb));
frame.yuy2 = rgbBgndIm;
frame.yuy2(~isnan(rgbCBIm)) = rgbCBIm(~isnan(rgbCBIm));
figure,imagesc(frame.yuy2);

frame.z = frame.z*4;
% CB = CBTools.Checkerboard(frame.i,'expectedGridSize',cbGridSz); 
% pts = CB.getGridPointsList;
% imshow(frame.i);
% hold on
% plot(pts(:,1),pts(:,2),'r*')

save('simulatedCB.mat','frame','camerasParams');
