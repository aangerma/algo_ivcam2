function validationSummery(dirPath)
if(nargin==0)
    dirPath = 'C:\Users\ychechik\Desktop\testPlanefit';
end
%% Temporal spatial noise
temporalSpatialNoise(dirPath);

%% Spatial distortion
spatialDistortion(dirPath);

%% Temporal depth noise
temporalDepthNoise(dirPath);

%% zSTD
zSTD(dirPath);

%% fill rate
fillRate(dirPath);

end


function temporalSpatialNoise(dirPath)

dirPath = fullfile(dirPath,'checkerboard');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.tiff'));
% d = d(contains(d,'.bin') & contains(d,'IR'));
d = fullfile(dirPath,d);


[gridsX,gridsY] = cellfun(@(x) Validation.findGrid(imread(x)),d,'uni',0);
% [gridsX,gridsY] = cellfun(@(x) Validation.findGrid(io.readBin(x)),d,'uni',0);


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

figure(14145);clf
hold on;
cellfun(@(x,y) plot(x,y,'.k'),gridsX,gridsY,'uni',0);
plot(meanGridX(:),meanGridY(:),'+b')
arrows = cellfun(@(x,y) sqrt(2*y(1))*x(:,1)',pcaMat,var,'uni',0);
arrows = cell2mat(arrows(:));
quiver(meanGridX(:),meanGridY(:),arrows(:,1),arrows(:,2),0)


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

function spatialDistortion(dirPath)
dirPath = fullfile(dirPath,'checkerboard','fine');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.tif'));
% d = d(contains(d,'.bin') & contains(d,'IR'));
d = fullfile(dirPath,d);

% imFn = 'C:\Users\ychechik\Desktop\11.tif';
im = imread(d{1});


[e,s,d]=Calibration.aux.evalProjectiveDisotrtion(im);

figure(343424);
aa(1)=subplot(121);
imagesc(im);title('Input');
hold on
plot(d(1,:),d(2,:),'.g',s(1,:),s(2,:),'ro');axis image
colormap gray
hold off
aa(2)=subplot(122);
quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:),'k');title(sprintf('Output (rms err = %f)',e));
set(aa(2),'ydir','reverse');
axis image
linkaxes(aa);
drawnow;

end


function temporalDepthNoise(dirPath)
dirPath = fullfile(dirPath,'wall25','500');
d = dir(dirPath);
d = {d.name};
d = d(contains(d,'.bin') &contains(d,'Depth') );
d = fullfile(dirPath,d);


i = io.readBin(d{1},'type','binz');
f = figure;imagesc(i);title('choose the plane rect for temporalDepthNoise...')
rect = getrect();
rect = round(rect);
close(f);
%

Is = cellfun(@(x) x(rect(2):(rect(2)+rect(4)),rect(1):(rect(1)+rect(3))), cellfun(@(x) io.readBin(x,'type','binz'), d,'uni',0), 'uni',0);

stdZIm = std(double(reshape(cell2mat(Is),size(Is{1},1),size(Is{2},2),[])),[],3);


figure;imagesc(stdZIm)
end


function zSTD(dirPath)
dirPath = fullfile(dirPath,'wall25');
d = dir(dirPath);
d(1:2) = []; %'.' '..'
d = {d.name};
subdirsNum = sort(  cell2mat( cellfun(@(x) str2double(x),  d,'uni',0)) );
subdirs = cellfun(@(x) num2str(x), num2cell( subdirsNum ),'uni',0);

imageS = struct();
% % % figure(2523);clf;
for i=1:length(subdirs)
    d = dir(fullfile(dirPath,subdirs{i}));
    d = {d.name};
    d = d(contains(d,'.bin') & contains(d,'Depth'));
    imageS.(['I' subdirs{i}]) = io.readBin(fullfile(dirPath,subdirs{i},d{1}),'type','binz');
    % % %     tabplot;imagesc( imageS.(['I' subdirs{i}]));
end

sz = size(imageS.(['I' subdirs{1}]));
[x,y] = meshgrid(1:sz(2),1:sz(1));

%get fovMask
f = figure(245242);clf;
imagesc(imageS.(['I' subdirs{end}]));
title('choose the plane rect for zSTD...');
rect = round(getrect);
close(f);
% rect = [271   175   105   148];

fovMask = false(size(x));
fovMask(rect(2):(rect(2)+rect(4)),rect(1):(rect(1)+rect(3))) = true;

vect = cell(size(subdirs));
distFromPlane = cell(size(subdirs));
inliersOut = cell(size(subdirs));
zstd = zeros(size(subdirs));
for i=1:length(subdirs)
    [vect{i},distFromPlane{i},inliersOut{i}] = planeFitRansac(x,y,double(imageS.(['I' subdirs{i}])),fovMask);
    zstd(i) = std(distFromPlane{i}(fovMask));
end
figure;plot(subdirsNum,zstd);title('z std');xlabel('dist from plane [mm]');ylabel('std');
end


function fillRate(dirPath)
dirPath = fullfile(dirPath,'ndfilter');
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
%     tabplot;imagesc( imageS.(subdirs{i}));
end


%get fovMask
f = figure(245242);clf;
imagesc(imageS.(subdirs{end}));
title('choose the plane rect for fillRate...');
rect = round(getrect);
close(f);
fovMask = false(size( imageS.(subdirs{end})));
fovMask(rect(2):(rect(2)+rect(4)),rect(1):(rect(1)+rect(3))) = true;

fillRate = zeros(size(subdirs));
for i=1:length(subdirs)
    I = imageS.(subdirs{i});
    fillRate(i) = sum(I(fovMask)~=0)/numel(I(fovMask))*100;
end

figure;plot(1:length(subdirs),fillRate);title('fill Rate');xlabel('nd type');ylabel('fill rate [%]');
xticks(1:length(subdirs));
xticklabels(subdirs);
end