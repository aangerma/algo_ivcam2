function [res] = mos(irImg, zImg, expectedGridSize, verbose)
irImg = double(irImg);
zImg = double(zImg);

if(~exist('expectedGridSize','var'))
    expectedGridSize=[];
end
if(~exist('verbose','var'))
    verbose=false;
end

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

% compute cell centers
centers = (pts(1:end-1,1:end-1,:) + pts(1:end-1,2:end,:) +...
    pts(2:end,1:end-1,:) + pts(2:end,2:end,:))/4;

if (verbose)
    figure; imagesc(irImg);
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

fCrop = 0.45;

barW = zeros(size(pts,1)-1, (size(pts,2)-1)/2);
barH = zeros(size(pts,1)-1, (size(pts,2)-1)/2);

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
        
        [x0 i0] = max([R(1,1) R(3,1)]);
        i0Min = iff(i0 == 1, 3, 1);
        x0t = (R(i0Min+1,1) - x0)/(R(i0Min+1,1) - R(i0Min,1));
        
        [x1 i1] = min([R(2,1) R(4,1)]);
        i1Max = iff(i1 == 1, 4, 2);
        x1t = (R(i1Max-1,1) - x1)/(R(i1Max-1,1) - R(i1Max,1));
        
        RR = R; % R rectified
        RR(i0Min,:) = R(i0Min,:)*x0t + R(i0Min+1,:)*(1-x0t);
        RR(i1Max,:) = R(i1Max,:)*x1t + R(i1Max-1,:)*(1-x1t);
        
        p0 = (RR(1,:) + RR(3,:))/2;
        p1 = (RR(2,:) + RR(4,:))/2;
        tunnelHeight = ceil(min(RR(3,2) - RR(1,2), RR(4,2) - RR(2,2)));
        
        k = (ib + 1)/2;
        [barW(j,k), barH(j,k)] = analyzeHorizontalMos(zImg, p0, p1, tunnelHeight);
        
        %[hTrans(i,j),hCont(i,j)] = analyzeHorizontalMos(ir, p0, p1, tunnelWidth);
    end
end


xPts(1,:) = reshape(pt(:,1), gridSize);

res.gridSize = gridSize;
res.points = pt;

figure; imagesc(irImg); hold on; plot(pt(:,1), pt(:,2), '+r');

pts=reshape(pt(:,1)+1j*pt(:,2),gridSize);

if abs(real(pts(1,1)) - real(pts(1,2))) < abs(imag(pts(1,1)) - imag(pts(1,2)))
    pts = pts.';
end

if real(pts(1,1)) > real(pts(1,end))
    pts = fliplr(pts);
end

if imag(pts(1,1)) > imag(pts(end,1))
    pts = flipud(pts);
end

hSize = [size(pts,1) size(pts,2)-1];
hTrans = zeros(hSize);
hCont = zeros(hSize);
for j=1:hSize(2)
    for i=1:hSize(1)
        p0 = pts(i, j);
        p1 = pts(i, j+1);
        [hTrans(i,j),hCont(i,j)] = analyzeHorizontalEdge(irImg, p0, p1, tunnelWidth);
    end
end

res.horizMin = min(hTrans(:));
res.horizMax = max(hTrans(:));
res.horizMean = mean(hTrans(:));
res.horizStd = std(hTrans(:));

res.vertMin = min(vTrans(:));
res.vertMax = max(vTrans(:));
res.vertMean = mean(vTrans(:));
res.vertStd = std(vTrans(:));

cont = [vCont(:);hCont(:)];
res.contMin = min(cont(:));
res.contMax = max(cont(:));
res.contMean = mean(cont(:));
res.contStd = std(cont(:));

end
    
function [width,height] = analyzeHorizontalMos(zImg, p0, p1, tunnelWidth)
subSamples = 4;

x0 = p0(1); x1 = p1(1);
y0 = p0(2); y1 = p1(2);

hLine = polyfit([x0 x1], [y0 y1], 1);

xRange = ceil(x0):floor(x1);
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
    zInterp(:,ix) = interp1(yRange, zImg(yRange,x),yInterpRange+yCenters(ix));
end

% plane fit
[Y, X] = ndgrid(1:size(zInterp,1),1:size(zInterp,2));
N = size(zInterp,1);
RM = floor(N/3); % fit plane to 1 third from top and bottom
R = [1:RM N-RM+1:N];
A = [vec(Y(R,:)) vec(X(R,:)) ones(numel(R)*size(zInterp,2),1)];
p = (A'*A)\(A'*vec(zInterp(R,:)));
zf = Y(:)*p(1)+X(:)*p(2)+p(3);
%figure; mesh(zInterp);
%hold on; mesh(reshape(zf, size(zInterp)));

zFixed = zInterp - reshape(zf, size(zInterp));
%figure; imagesc(zInterp);

zCurve = mean(zFixed,2);
zIntegral = cumsum(zCurve);

zSubMM = 8;

[fitCurve,~,~, rise, sigm_params] = fitting.riseFitting(zIntegral);
width = rise / subSamples;
pxPeak = round(sigm_params(3));
height = abs(median(zFixed(pxPeak-1:pxPeak+1)))/zSubMM;

%figure; plot([zIntegral fitCurve]);

end


