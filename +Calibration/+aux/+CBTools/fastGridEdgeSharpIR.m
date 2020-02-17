function [score, results] = fastGridEdgeSharpIR(frames, gridSize, gridPointsList, params,frameFieldName)
% Slim version of gridEdgeSharpIR (for description - see original metric)

if ~exist('frameFieldName','var')
    frameFieldName = 'i';
end

if ~exist('params','var')
    params = Validation.aux.defaultMetricsParams();
end

if isfield(params,'target')
    if isfield(params.target,'target')
        Validation.aux.testCheckerboard (params.target.target)
    end
end

if ~isfield(params,'imageRotatedBy180Flag')
    params.imageRotatedBy180Flag = false;
end

meanFrame = struct();
meanFrame.i = Validation.aux.meanImage(frames, frameFieldName);
res1 = edgeTrans(meanFrame, gridSize, gridPointsList);

fnames = fieldnames(res1);
res1 = struct2table(res1);
for i = 1:length (fnames)
    fname = char(fnames(i));
    results.([fname,'AF']) = res1.(fname);
end

results.score = 'horzWidthMeanAF';
results.units = 'pixels';
score = results.(results.score);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function results = edgeTrans(frame, gridSize, gridPointsList, varargin)

p = inputParser;
addRequired(p,'ir');
addParameter(p,'tunnelWidth',7)
addParameter(p,'expectedGridSize',[])
addParameter(p,'targetType','')
addParameter(p,'imageRotatedBy180Flag',false)
parse(p,frame,varargin{:})

pts = reshape(gridPointsList(:,1)+1j*gridPointsList(:,2),gridSize);
ir = double(frame.i);
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
pix_shift = 2;

for j=1:hSize(2)
    for i=1:hSize(1)
        p0 = pts(i, j);
        p1 = pts(i, j+1);
        totalWidth = pix_shift + p.Results.tunnelWidth;
        if abs(imag(p0)-size(ir,1))<totalWidth ||  abs(imag(p0)-1)<totalWidth || abs(imag(p1)-size(ir,1))<totalWidth ||  abs(imag(p1)-1)<totalWidth
            hTrans(i,j) = nan;
        else
            hTrans(i,j) = analyzeHorizontalEdge(ir, p0, p1, p.Results.tunnelWidth,pix_shift);
        end
        
    end
end

res = struct('horzWidth',hTrans);
fnames = fieldnames(res); 
% res = struct2table(res);

for i=1:length (fnames)
    fname = char(fnames(i));
    headername = fname;
    a = res.(fname)(:);
    results.([headername,'Min']) = nanmin(a);
    results.([headername,'Max'])= nanmax(a);
    results.([headername,'Mean']) = nanmean(a);
    results.([headername,'Stdev']) = nanstd(a);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function width = analyzeHorizontalEdge(ir, p0, p1, tunnelWidth,pix_shift)
% Uncomment this section to plot the edges that participiate in the
% calculation
% figure(1);
% hold on;
% plot([real(p0),real(p1)],[imag(p0),imag(p1)],'r','linewidth',2)
try
    subSamples = 4;
    % manual polyfit
    lineSlope = (imag(p1)-imag(p0))/(real(p1)-real(p0));
    hLine = [lineSlope, imag(p0)-lineSlope*real(p0)];
    % preparations
    xRange = ceil(real(p0)+pix_shift):floor(real(p1)-pix_shift);
    yCenters = polyval(hLine, xRange);
    yInterpRange = -tunnelWidth/2:(1/subSamples):tunnelWidth/2;
    yTransImg = ir(round(yInterpRange'+yCenters)+(xRange-1)*size(ir,1)); % fast one-shot sampling
    yTrans = mean(yTransImg,2);
    % approximation of rise fitting
    fitCurve = smooth(yTrans,3);
    mM = minmax(fitCurve');
    testPoints = mM(1)+[0.1,0.9]*diff(mM);
    testPointsX = zeros(1,2);
    for k = 1:2
        ind = find(fitCurve<testPoints(k),1,'last');
        a = fitCurve(ind+1)-fitCurve(ind);
        b = fitCurve(ind)-a*ind;
        testPointsX(k) = (testPoints(k)-b)/a;
    end
    rise = diff(testPointsX);
    width = rise / subSamples;
catch
    width = nan;
end
end


