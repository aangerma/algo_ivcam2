function var = simulatePitchScaleError()
% simulate 1 frame
ff = 20e+3;
fs = 30;
pitchFactor = 0.2;
nSamples = 480*640;
t = linspace(0,1/fs ,nSamples);
t_full_y_cycle = find(t>1/ff,1);

fovy = 50;
fovx = 60;


angx = -fovx/4+t*fs*fovx/2;
angy = fovy/4*sin(2*pi*ff*t);
pitch = angx*pitchFactor;
wrong_pitch = pitch*0.5;

angy_pitched = angy+pitch;
figure,plot(angx,angy_pitched );


angy_wrong_pitched = angy+wrong_pitch;

angx = circshift(angx(:),5*round(t_full_y_cycle));

v_gt = ang2vec(angx(:),angy_pitched(:));
v_false = ang2vec(angx(:),angy_wrong_pitched(:));

c_gt = getColorFromV(v_gt);
c_false = getColorFromV(v_false);

% figure,
% tabplot;
% scatter(angx(:),angy_pitched(:),10,c_gt(:),'filled');
% tabplot;
% scatter(angx(:),angy_wrong_pitched(:),10,c_false(:),'filled');


% Show spherical images 
% [spx,spy] = meshgrid(linspace(-fovx/4,fovx/4,640),linspace(-fovy/4,fovy/4,480));
% gtIm = griddata(angx(:),angy_pitched(:),c_gt(:),spx(:),spy(:));
% gtIm = reshape(gtIm,480,640);
% badIm = griddata(angx(:),angy_wrong_pitched(:),c_false(:),spx(:),spy(:));
% badIm = reshape(badIm,480,640);
% figure,
% tabplot;
% imagesc(gtIm);
% tabplot;
% imagesc(badIm);
% 
% % Show in regular mode
% [xIm,yIm] = meshgrid(1:640,1:480);
% [angxGrid,angyGrid] = xy2ang(xIm,yIm,fovx,fovy);
% gtIm = griddata(angx(:),angy_pitched(:),c_gt(:),angxGrid(:),angyGrid(:));
% gtIm = reshape(gtIm,480,640);
% badIm = griddata(angx(:),angy_wrong_pitched(:),c_false(:),angxGrid(:),angyGrid(:));
% badIm = reshape(badIm,480,640);
% figure,
% tabplot;
% imagesc(gtIm);
% tabplot;
% imagesc(badIm);
% 

% Split by raise and fall
[axU,ayU,axD,ayD,cU,cD] = splitUpDown(angx,angy_wrong_pitched,c_false);
[xIm,yIm] = meshgrid(1:640,1:480);
[angxGrid,angyGrid] = xy2ang(xIm,yIm,fovx,fovy);
upIm = griddata(axU(:),ayU(:),cU(:),angxGrid(:),angyGrid(:));
upIm = reshape(upIm,480,640);
downIm = griddata(axD(:),ayD(:),cD(:),angxGrid(:),angyGrid(:));
downIm = reshape(downIm,480,640);
figure,
tabplot;
imagesc(upIm);
tabplot;
imagesc(downIm);

var = cornerVar(upIm,downIm);

end
function [axU,ayU,axD,ayD,cU,cD] = splitUpDown(angx,angy,c)
raise = diff(angy)>0;
raise(end+1) = 1;
axU = angx(raise);
ayU = angy(raise);
axD = angx(~raise);
ayD = angy(~raise);
cU = c(raise);
cD = c(~raise);


end
function pixVar = cornerVar(gtIm,badIm)
[p1,~] = detectCheckerboardPoints(normByMax(badIm)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
[p2,~] = detectCheckerboardPoints(normByMax(gtIm)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
       
pixVar = var((p1(:,2))-(p2(:,2)));

end
function [angx,angy] = xy2ang(x,y,fovx,fovy)
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
laserIncidentDirection = [0,0,-1]';
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
rangeR = xyz2nrmxy(oXYZfunc(angles2xyz( fovx*0.25,                   0)));rangeR=rangeR(1);
rangeL = xyz2nrmxy(oXYZfunc(angles2xyz(-fovx*0.25,                   0)));rangeL=rangeL(1);
rangeT = xyz2nrmxy(oXYZfunc(angles2xyz(0                   , fovy*0.25)));rangeT =rangeT (2);
rangeB = xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-fovy*0.25)));rangeB=rangeB(2);

xys = [640;480]./[rangeR-rangeL;rangeT-rangeB];
xy00 = [rangeL;rangeB];


xy = [x(:) y(:)];
xy = bsxfun(@rdivide,xy,xys');
xy = bsxfun(@plus,xy,xy00');
xynrm = xy';


v = normr([xynrm' ones(size(xynrm,2),1)]);
n = normr(v - repmat(laserIncidentDirection',size(v,1),1) );

angy = asind(n(:,2));
angx = atand(n(:,1)./n(:,3));
end
function color = getColorFromV(v)
% Assume CB at 500mm
% If v lands in white, return 1. Black returns 0. Outside returns 0.5;
v = v*400;

tileSizeMM = 30;
h=9;
w=13;
ox = linspace(-1,1,w)*(w-1)*tileSizeMM/2;
oy = linspace(-1,1,h)*(h-1)*tileSizeMM/2;

xInd = floor((v(1,:)-ox(1))/tileSizeMM);
yInd = floor((v(2,:)-oy(1))/tileSizeMM);

color = (-1).^(xInd+yInd)*0.5+0.5;
color(xInd<0 | xInd>=w-1 | yInd<0 | yInd>=h-1) = 0.5;


end
function v = ang2vec(angxQin,angyQin)
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
laserIncidentDirection = [0,0,-1]'; %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));

v = oXYZfunc(angles2xyz(angxQin(:),angyQin(:)));
v = v./v(3,:);
end