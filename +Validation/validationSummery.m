function validationSummery(dirPath)
vis = 'off';


if(nargin==0)
    dirPath = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\testPlanefit';%'C:\Users\ychechik\Desktop\testPlanefit';
end

s = build4start(dirPath,vis);
startHTML(s);

%% Temporal spatial noise
  temporalSpatialNoise(s);

%% Spatial distortion
spatialDistortion(s);

%% Temporal depth noise
temporalDepthNoise(s);

%% zSTD
zSTD(s);

%% fill rate
fillRate(s);


closeHTML(s)
end

function s = build4start(dirPath,vis)
resDirName = fullfile(dirPath,'res');
if(~exist(resDirName,'dir'))
    mkdirSafe(resDirName);
end
imDirName = fullfile(resDirName,'images');
if(~exist( imDirName,'dir'))
    mkdirSafe(imDirName);
end
logfn = fullfile(resDirName,'log.html');
fid = fopen(logfn,'w');

s.dirPath = dirPath;
s.imDirName = imDirName;
s.fid = fid;
s.vis = vis;
end

function startHTML(s)

% fprintf(s.fid,'<!DOCTYPE html><html><body>\n');
fprintf(s.fid,...
['<!DOCTYPE html>\n'...
'<html>\n'...
'<head>\n'...
'<style>\n'...
'table {\n'...
'    font-family: arial, sans-serif;\n'...
'    border-collapse: collapse;\n'...
'    width: 100%%;\n'...
'}\n'...
'\n'...
'td, th {\n'...
'    border: 1px solid black;\n'...
'    text-align: left;\n'...
'    padding: 8px;\n'...
'}\n'...
'\n'...
'tr:nth-child(odd) {\n'...
'    background-color: #dddddd;\n'...
'}\n'...
'</style>\n'...
'</head>\n'...
'<body>\n'...
'\n'...
'<table>\n']);
end


function writeIm2HTML(s,Ifn)
dispSize = 640; %only enter width- will retain aspact ratio
coeff = 3.5;
dispSize = round(dispSize*coeff);
fprintf(s.fid,'<img src="%s" alt="" width="%s">\n',Ifn,num2str(dispSize));% height="%s"\n>',Ifn,num2str(dispSize(2)),num2str(dispSize(1)));
end

function writeTitle2HTML(s,tit)
 fprintf(s.fid,'<tr><td><h1>%s</h1></td></tr>\n',tit);
%fprintf(s.fid,'<tr><th>%s</th></tr>\n',tit);

end
function writeTxt2HTML(s,txt)
 fprintf(s.fid,'<h3>%s</h3>\n',txt);
% fprintf(s.fid,'<th>%s</th>\n',txt);

end

function startTableCellHTML(s)
fprintf(s.fid,'<tr><td>\n');
end
function endTableCellHTML(s)
fprintf(s.fid,'</td></tr>\n');
end

function closeHTML(s)
fprintf(s.fid,'</table></body></html>\n');
fclose(s.fid);
end


function temporalSpatialNoise(s)

dirPath = fullfile(s.dirPath,'checkerboard');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.tiff'));
d = fullfile(dirPath,d);


[gridsX,gridsY] = cellfun(@(x) Validation.findGrid(imread(x)),d,'uni',0);


szBrd = size(gridsX{1});
numIm = length(d);

meanGridX = mean(reshape(cell2mat(gridsX),szBrd(1),szBrd(2),[]),3);
meanGridY = mean(reshape(cell2mat(gridsY),szBrd(1),szBrd(2),[]),3);

xZero = cellfun(@(x) x-meanGridX , gridsX, 'uni',0);
yZero = cellfun(@(y) y-meanGridY , gridsY, 'uni',0);

x3d = mat2cell(reshape(cell2mat(xZero),szBrd(1),szBrd(2),[]), ones(szBrd(1),1),ones(szBrd(2),1),numIm);
y3d = mat2cell(reshape(cell2mat(yZero),szBrd(1),szBrd(2),[]), ones(szBrd(1),1),ones(szBrd(2),1),numIm);

%pcaMat - each col is a vector of principle component in descending order
%var- var for HALF the principle component
[pcaMat,~,var] = cellfun(@(x,y) pca([vec(squeeze(x)) vec(squeeze(y))])  ,x3d,y3d,'uni',0);

f = figure('visible',s.vis);clf;maximize(f);
hold on;

arrows = cellfun(@(x,y) sqrt(2*y(1))*x(:,1)',pcaMat,var,'uni',0);
arrows = cell2mat(arrows(:));
k = 3;
quiver(meanGridX(:),meanGridY(:),k*arrows(:,1),k*arrows(:,2),0)

fn = fullfile(s.imDirName ,'temporalSpatialNoise.png');
saveas(f,fn,'png');

writeTitle2HTML(s,'temporalSpatialNoise')
startTableCellHTML(s)
 writeTxt2HTML(s,'over a set of checkerboard images captures. evaluate the std movement of each checkerboard crosspoint set.');

writeIm2HTML(s,fn)
endTableCellHTML(s)

if(0)
    % test
    t = linspace(0,2*pi,100000);
    x = sin(t)';
    y = 9*cos(t)';
    
    d = 30;
    m = [cosd(d) sind(d);-sind(d) cosd(d)];
    
    xy = (m*[x y]')';
    x = xy(:,1);
    y = xy(:,2);
    figure;plot(x,y);hold on;
    
    [pcaMat,~,var] = pca([x(:) y(:)]);
    quiver(0,0,sqrt(var(1)*2)*pcaMat(1),sqrt(var(1)*2)*pcaMat(2),0)
end
end

function spatialDistortion(s)
dirPath = fullfile(s.dirPath,'checkerboard','fine');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.tif'));
d = fullfile(dirPath,d);

im = imread(d{1});


[e,ss,d]=Calibration.aux.evalProjectiveDisotrtion(im);

f = figure('visible',s.vis);maximize(f);
aa(1)=subplot(121);
imagesc(im);title('Input');
hold on
plot(d(1,:),d(2,:),'.g',ss(1,:),ss(2,:),'ro');axis image
colormap gray
hold off
aa(2)=subplot(122);
quiver(ss(1,:),ss(2,:),d(1,:)-ss(1,:),d(2,:)-ss(2,:),'k');title(sprintf('Output (rms err = %f)',e));
set(aa(2),'ydir','reverse');
axis image
linkaxes(aa);
drawnow;

fn = fullfile(s.imDirName ,'spatialDistortion.png');
saveas(f,fn,'png');

writeTitle2HTML(s,'spatialDistortion')
 startTableCellHTML(s)
 writeTxt2HTML(s,'Capture an image of checkerboard plane covering the maximal FOV. Evaluate projective residual distortion');

writeIm2HTML(s,fn)
endTableCellHTML(s)

end


function temporalDepthNoise(s)
dirPath = fullfile(s.dirPath,'wall25','500');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.bin') &contains(d,'Depth') );
d = fullfile(dirPath,d);


i = io.readBin(d{1},'type','binz');

rectMask = findPlaneInIm(i);

Is = cellfun(@(x) x(rectMask), cellfun(@(x) io.readBin(x,'type','binz'), d,'uni',0), 'uni',0);

stdZIm = std(double(cell2mat(Is)),[],2);

f = figure('visible',s.vis);maximize(f);
imshowpair(i,rectMask);title('chosen mask on depth image')
fn = fullfile(s.imDirName ,'temporalDepthNoise.png');
saveas(f,fn,'png');

writeTitle2HTML(s,'temporalDepthNoise')
startTableCellHTML(s)
writeTxt2HTML(s,'capture a 25% reflectivity wall. For each of the pixels evaluate the standard deviation over time of the depth and IR readouts (with, and without post processing)');

writeTxt2HTML(s,sprintf('Results: mean = %f, std = %f, min = %f, max = %f',mean(stdZIm),std(stdZIm),min(stdZIm),max(stdZIm)));
writeIm2HTML(s,fn)
endTableCellHTML(s)
end


function zSTD(s)
dirPath = fullfile(s.dirPath,'wall25');
d = dir(dirPath);
d(1:2) = []; %'.' '..'
d = {d.name};
subdirsNum = sort(  cell2mat( cellfun(@(x) str2double(x),  d,'uni',0)) );
subdirs = cellfun(@(x) num2str(x), num2cell( subdirsNum ),'uni',0);

imageS = struct();
for i=1:length(subdirs)
    d = dir(fullfile(dirPath,subdirs{i}));
    d = {d.name};
    d = d(contains(d,'.bin') & contains(d,'Depth'));
    imageS.(['I' subdirs{i}]) = io.readBin(fullfile(dirPath,subdirs{i},d{1}),'type','binz');
end

sz = size(imageS.(['I' subdirs{1}]));
[x,y] = meshgrid(1:sz(2),1:sz(1));

fovMask = findPlaneInIm(imageS.(['I' subdirs{end}]));

vect = cell(size(subdirs));
distFromPlane = cell(size(subdirs));
inliersOut = cell(size(subdirs));
zstd = zeros(size(subdirs));
for i=1:length(subdirs)
    [vect{i},distFromPlane{i},inliersOut{i}] = planeFitRansac(x,y,double(imageS.(['I' subdirs{i}])),fovMask);
    zstd(i) = std(distFromPlane{i}(fovMask));
end
f = figure('visible',s.vis);maximize(f);
plot(subdirsNum,zstd);title('z std');xlabel('dist from plane [mm]');ylabel('std');
fn = fullfile(s.imDirName ,'zSTD.png');
saveas(f,fn,'png');

writeTitle2HTML(s,'zSTD')
startTableCellHTML(s);
writeTxt2HTML(s,'Capture a 25% reflecticty plane from various distances. Construct the minimum FOV that overlaps all captures, and use only this FOV for the data analysis. In each one of the recordings, find the best describing plane (a.k.a planefit), with outliers removal mechanism (ransac). Estimate the Euclidean distance of each point from the given plane.');
writeIm2HTML(s,fn)


f = figure('visible',s.vis);maximize(f);
imshowpair(imageS.(['I' subdirs{end}]),fovMask);title('chosen mask on depth image');
fn = fullfile(s.imDirName ,'zSTDpair.png');
saveas(f,fn,'png');

writeIm2HTML(s,fn)
endTableCellHTML(s)
end


function fillRate(s)
dirPath = fullfile(s.dirPath,'ndfilter');
d = dir(dirPath);
d(1:2) = []; %'.' '..'
d = {d.name};
subdirs = d(contains(d,'f'));

imageS = struct();
for i=1:length(subdirs)
    d = dir(fullfile(dirPath,subdirs{i}));
    d = {d.name};
    d = d(contains(d,'.bin') & contains(d,'Depth'));
    
    imageS.(subdirs{i}) = io.readBin(fullfile(dirPath,subdirs{i},d{1}),'type','binz');
end



fovMask = findPlaneInIm(imageS.(subdirs{1}));


fillRate = zeros(size(subdirs));
for i=1:length(subdirs)
    I = imageS.(subdirs{i});
    fillRate(i) = sum(I(fovMask)~=0)/numel(I(fovMask))*100;
end

f = figure('visible',s.vis);maximize(f);
plot(1:length(subdirs),fillRate);title('fill Rate');xlabel('OD (optical density)');ylabel('fill rate [%]');

%OD = -log10(1/T);
%OD - optical density
%T - transmission rate (0<=T<=1)
%ex: when writen in the dir name: "f02" -> OD=0.2 -> transmissionRate=63%
od = cellfun(@(x) [x(2) '.' x(3:end)], subdirs,'uni',0);
xticks(1:length(od));
xticklabels(od);
fn = fullfile(s.imDirName ,'fillRate.png');
saveas(f,fn,'png');

writeTitle2HTML(s,'fillRate')
startTableCellHTML(s)
writeTxt2HTML(s,'Capture 25% reflectivity perpendicular plane at 1m, with Nd filter over the sensor at different opacity levels. In each opacity level calculate the number of valid pixels on the target');
writeIm2HTML(s,fn)

f = figure('visible',s.vis);maximize(f);
imshowpair(imageS.(subdirs{1}),fovMask);title('chosen mask on depth image');
fn = fullfile(s.imDirName ,'fillRatepair.png');
saveas(f,fn,'png');

writeIm2HTML(s,fn)
endTableCellHTML(s)
end


function closeBW = findPlaneInIm(I)
%%
fovMaskRatio = 10; %ratio from image that the board is for sure inside
inliersBoardErrorInMm = 100; %allowd error form plane in mm


sz = size(I);
center = ceil(size(I)/2);
fovMask = false(sz);
fovMask(round(center(1)-sz(1)/fovMaskRatio):round(center(1)+sz(1)/fovMaskRatio),round(center(2)-sz(2)/fovMaskRatio):round(center(2)+sz(2)/fovMaskRatio)) = true;

[x,y] = meshgrid(1:size(I,2),1:size(I,1));
[~,distFromPlane] = planeFitRansac(x,y,double(I),fovMask);


inliers = abs(distFromPlane)<inliersBoardErrorInMm;

%get biggest connected component
CC = bwconncomp(inliers);
numPixels = cellfun(@numel,CC.PixelIdxList);
[~,idx] = max(numPixels);
rectMask = false(sz);
rectMask(CC.PixelIdxList{idx}) = true;



se = strel('disk',10);
closeBW = imclose(rectMask,se);

assert(closeBW(center(1),center(2))==true,'center pixel is not in board for some reason...')


% % % figure;subplot(211);imagesc(I);subplot(212);imagesc(closeBW)
end