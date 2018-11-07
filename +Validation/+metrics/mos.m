function [score, res] = mos(frame, params, expectedGridSize)
irImg = double(frame.i);
zImg = double(frame.z);

if(~exist('expectedGridSize','var'))
    expectedGridSize=[];
end

if ~exist('params','var')
    params = Validation.aux.defaultMetricsParams();
end

verbose = params.verbose;


%% fine grid
[pt, gridSize] = Validation.aux.findCheckerboard(irImg, expectedGridSize);

if (any(gridSize < 2))
    if verbose
        warning('Board is not detected');
        res = [];
        return;
    end
end

%% complete grid

pts = zeros([gridSize + 2 2]);
pts(2:end-1,2:end-1,:) = reshape(pt, [gridSize 2]);
% extrapolate external corners
pts(1,:,:) = 2*pts(2,:,:) - pts(3,:,:);
pts(end,:,:) = 2*pts(end-1,:,:) - pts(end-2,:,:);
pts(:,1,:) = 2*pts(:,2,:) - pts(:,3,:);
pts(:,end,:) = 2*pts(:,end-1,:) - pts(:,end-2,:);

%% flip dimmensions to make them consistent
if abs(pts(1,1,1) - pts(end,1,1)) > abs(pts(1,1,1) - pts(1,end,1))
    pts = permute(pts,[2 1 3]);
end

if (pts(1,1,2) > pts(end,1,2))
    pts = flip(pts,1);
end

if (pts(1,1,1) > pts(1,end,1))
    pts = flip(pts,2);
end

%% compute cell centers
centers = (pts(1:end-1,1:end-1,:) + pts(1:end-1,2:end,:) +...
    pts(2:end,1:end-1,:) + pts(2:end,2:end,:))/4;

if (verbose)
    figure(17211); imagesc(irImg);
    hold on; plot(pts(:,:,1), pts(:,:,2), '+r');
    hold on; plot(centers(:,:,1), centers(:,:,2), '+k');
end

%% detect horizontal - vertical position
% make sure the too-right cell is white
horiz = false;
% if cell(1,1) is black
if (irImg(round(centers(1,1,2)),round(centers(1,1,1))) < irImg(round(centers(1,2,2)),round(centers(1,2,1))))
    horiz = true;
end

fCrop = 0.3;

outSize = [size(pts,1)-1 (size(pts,2)-1)/2];
barW = zeros(outSize);
barH = zeros(outSize);
barC = zeros([outSize 2]);
zC = zeros(outSize);
blobNoise = zeros(outSize);

%% cell iteratons
for j=1:size(pts,1)-1
    for ib=1:2:size(pts,2)-1
        i = iff(bitand(ib+j+horiz,1) == 0, ib, ib+1);
        R = squeeze([pts(j,i,:) pts(j,i+1,:) pts(j+1,i,:) pts(j+1,i+1,:)]);
        c = sum(R,1)/4;
        R = R*(1-fCrop) + c*fCrop;
        if (verbose)
            plot(c(1), c(2), 'Or');
            patch(R(:,1), R(:,2), 'r');
        end
        
        pc0 = (R(1,:)+R(3,:))/2;
        pc1 = (R(2,:)+R(4,:))/2;
        
        t0 = (max([R(1,1) R(3,1)]) - pc0(1))/(pc1(1) - pc0(1));
        t1 = (pc1(1) - min([R(2,1) R(4,1)]))/(pc1(1) - pc0(1));

        p0 = pc0*(1-t0) + pc1*t0;
        p1 = pc1*(1-t1) + pc0*t1;
        
        tunnelHeight = ceil(min(R(3,2),R(4,2)) - max(R(1,2),R(2,2)));
        
        k = (ib + 1)/2;
        [barW(j,k), barH(j,k), zC(j,k), blobNoise(j,k)] = ...
            analyzeHorizontalMos(zImg, p0, p1, tunnelHeight, params.camera);
        barC(j,k,:) = c;
    end
end

% j == 2 && ib == 7
% j == 8 && ib == 1


if (verbose)
    figure(17211); hold off;
    figure(17213); imagesc(barW); title('Bar widths');
    figure(17214); imagesc(barH); title('Bar heights');
end

bar0 = barC; bar0(:,:,2) = barC(:,:,2) - barW/2;
bar1 = barC; bar1(:,:,2) = barC(:,:,2) + barW/2;

K = double(params.camera.K);
v0 = Validation.aux.pointsToVertices(reshape(bar0, [], 2), zC(:), K);
v1 = Validation.aux.pointsToVertices(reshape(bar1, [], 2), zC(:), K);
vd = v1 - v0;
barWmm = reshape(sqrt(dot(vd,vd,2)), size(barW));

res.gridSize = gridSize;
res.points = pt;

res.barWidth = barWmm;
res.barHeight = barH;

res.blobNoise = blobNoise;
res.meanBlobNoise = mean(blobNoise(:));

fNoise = scoreFun(0.8, 1.3);
res.probToSee = fNoise(barH ./ blobNoise);
res.npVisibleBars = sum(res.probToSee(:));
undetected = res.probToSee < 0.8;

areas = barWmm .* barH;
areas(undetected) = nan;
res.minArea = nanmin(areas(:));

bigUp = sum(vec(barH(1:2,:))) > sum(vec(barH(end-1:end,:)));
[wGT, hGT] = Validation.aux.mosHorizGroundTruth(bigUp);
gtArea = wGT .* hGT;
gtArea(undetected) = nan;
[res.minAreaGTreal, iMinGT] = nanmin(gtArea(:));
res.minAreaGT = areas(iMinGT);

dW = barWmm - wGT;
dW(undetected) = nan;
res.meanErrorWidthGT = nanmean(abs(dW(:)));
res.maxErrorWidthGT = nanmax(abs(dW(:)));
res.diffWidthGT = dW;

dH = barH - hGT;
dH(undetected) = nan;
res.meanErrorHeightGT = nanmean(abs(dH(:)));
res.maxErrorHeightGT = nanmax(abs(dH(:)));
res.diffHeightGT = dH;

res.meanSquareXsize = mean(vec(diff(squeeze(pts(:,:,1)),1,2)));
res.meanSquareYsize = mean(vec(diff(squeeze(pts(:,:,2)),1,1)));

score = res.minArea;
res.score = 'minArea';
res.units = 'mm^2';

end
    
function [width, height, zc, blobNoise] = analyzeHorizontalMos(zImg, p0, p1, tunnelWidth, camera)
subSamples = 4;
zSubMM = camera.zMaxSubMM;
maxHeight = 20; % in mm

x0 = p0(1); x1 = p1(1);
y0 = p0(2); y1 = p1(2);

hLine = polyfit([x0 x1], [y0 y1], 1);

xRangeCropMargin = 0.2 * (x1 - x0);
xRange = ceil(x0+xRangeCropMargin):floor(x1-xRangeCropMargin);

yCenters = polyval(hLine, xRange);
yCenter = mean([yCenters(1) yCenters(end)]);
yRangeLen = tunnelWidth + ceil(abs(yCenters(1)-yCenters(end))) + 2;
yRange0 = floor(yCenter - yRangeLen/2);
yRange1 = yRange0 + yRangeLen;
yRange = yRange0:yRange1;
yInterpRange = -tunnelWidth/2:(1/subSamples):tunnelWidth/2;
zInterp = zeros(length(yInterpRange), length(xRange));
for ix=1:length(xRange)
    x = xRange(ix);
    zInterp(:,ix) = interp1(yRange, zImg(yRange,x)/zSubMM,yInterpRange+yCenters(ix));
end

% plane fit
planeFitMargin = 0.3;
[Y, X] = ndgrid(1:size(zInterp,1),1:size(zInterp,2));
N = size(zInterp,1);
RM = floor(N*planeFitMargin); % fit plane to top and bottom margins
R = [1:RM N-RM+1:N];
A = [vec(Y(R,:)) vec(X(R,:)) ones(numel(R)*size(zInterp,2),1)];
p = (A'*A)\(A'*vec(zInterp(R,:)));
zf = Y(:)*p(1)+X(:)*p(2)+p(3);

zFixed = (zInterp - reshape(zf, size(zInterp)));
%figure; mesh(zInterp);
%hold on; mesh(reshape(zf, size(zInterp)));
%figure; imagesc(zInterp);
%figure; plot([zIntegral fitCurve]);

zCurve = mean(zFixed,2);
%figure; plot(zCurve);

zIntegral = cumsum(zCurve);
[fitCurve,~,~, rise, sigm_params] = fitting.riseFitting(zIntegral, [], false);
%figure; plot([zIntegral fitCurve]);

% z of the center of the region
zc = (sigm_params(3)*p(1)+((size(Y,2)+1)/2)*p(2)+p(3));

%% estimate blob noise
tMargin = zFixed(1:RM, :); % top margin region
bMargin = zFixed(N-RM+1:N, :); % bottom margin region

kerBlob = 1;
tBlobNoise = max(vec(abs(imgaussfilt(tMargin, [4*kerBlob kerBlob]))));
bBlobNoise = max(vec(abs(imgaussfilt(bMargin, [4*kerBlob kerBlob]))));
% min noise to ignore possible bar/its shadow in the marginal region
blobNoise = min(tBlobNoise, bBlobNoise);

%% validate results

width = rise / subSamples;
if (width < 0 || width > tunnelWidth*0.5)
    height = 0; width = 0;
    return;
end

qPeakMargin = 0.25;
iPeak = round(sigm_params(3));
if (iPeak < length(zCurve)*qPeakMargin || iPeak > length(zCurve)*(1-qPeakMargin))
    height = 0; width = 0;
    return;
end

height = -(median(zCurve(iPeak-1:iPeak+1)));
if (height < 0 || height > maxHeight)
    height = 0; width = 0;
    return;
end

qFitAreaRatio = 0.25;
orgArea = sum(abs(zCurve));
fitArea = abs(fitCurve(end));
if (orgArea * qFitAreaRatio > fitArea)
    height = 0; width = 0;
    return;
end

maxFitError = max(abs((zIntegral-fitCurve)));
fitRise = abs(fitCurve(end) - fitCurve(1));
qFitRiseRatio = 0.9;
if (fitRise * qFitRiseRatio < maxFitError)
    height = 0; width = 0;
    return;
end

%% take top and bottom margins and estimate noise relative to detected bar

%hBlobNoise = max(max(mean(tMargin,1)),max(mean(bMargin,1)));
%vBlobNoise = max(max(mean(tMargin,2)),max(mean(bMargin,2)));
%blobNoise = max(hBlobNoise, vBlobNoise);

% probToSee = 1.0;
% if (height / blobNoise < probToSee)
%     height = 0; width = 0;
%     return;
% end

end

function [f] = scoreFun(xMin, xMax)

c = mean([xMin xMax]);

f = @(x) tanh(4*(x-c)/(xMax-xMin))/2+0.5;

end

