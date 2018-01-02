function [errStat] = edgeTrans(ir,tunnelWidth,horizontalMargin,verbose)
ir = double(ir);
if(~exist('tunnelWidth','var'))
    tunnelWidth=7;
end
if(~exist('horizontalMargin','var'))
    horizontalMargin=3;
end
if(~exist('verbose','var'))
    verbose=false;
end

ir(sum(ir(:,2:end-1),2)==0,:)=[];

ir_=ir;

ir_(isnan(ir_))=0;
ir_ = histeq(normByMax(ir_));
% pt = Utils.findCheckerBoardCorners(ir_,boardSize,false);
[pt,bsz]=detectCheckerboardPoints(ir_);

boardSize = bsz - 1;
if(any(boardSize < 2))
    error('Board is not detected');
end

% boardSize=[9 13];%bsz-1
% if(~all(bsz-1==boardSize))
%     error('Bad binput image/board size');
% end
 
 
pts=reshape(pt(:,1)+1j*pt(:,2),boardSize);

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
for j=1:hSize(2)
    for i=1:hSize(1)
        p0 = pts(i, j);
        p1 = pts(i, j+1);
        hTrans(i,j) = analyzeHorizontalEdge(ir, p0, p1, tunnelWidth);
    end
end

vSize = [size(pts,1)-1 size(pts,2)];
vTrans = zeros(vSize);
irT = ir';
for j=1:vSize(2)
    for i=1:vSize(1)
        p0 = pts(i, j)'*1j;
        p1 = pts(i+1, j)'*1j;
        vTrans(i,j) = analyzeHorizontalEdge(irT, p0, p1, tunnelWidth);
    end
end

errStat.horizMin = min(hTrans(:));
errStat.horizMax = max(hTrans(:));
errStat.horizMean = mean(hTrans(:));
errStat.horizStd = std(hTrans(:));

errStat.vertMin = min(vTrans(:));
errStat.vertMax = max(vTrans(:));
errStat.vertMean = mean(vTrans(:));
errStat.vertStd = std(vTrans(:));


end
    
function width = analyzeHorizontalEdge(ir, p0, p1, tunnelWidth)

    hLine = polyfit([real(p0) real(p1)], [imag(p0) imag(p1)], 1);
    
    xRange = ceil(real(p0)+2):floor(real(p1)-2);
    yCenters = polyval(hLine, xRange);
    yCenter = mean([yCenters(1) yCenters(end)]);
    yRangeLen = tunnelWidth + ceil(abs(yCenters(1)-yCenters(end))) + 2;
    yRange0 = floor(yCenter - yRangeLen/2);
    yRange1 = yRange0 + yRangeLen;
    yRange = yRange0:yRange1;
    yInterpRange = -tunnelWidth/2:0.25:tunnelWidth/2;
    yTransImg = zeros(length(yInterpRange), length(xRange));
    for ix=1:length(xRange)
        x = xRange(ix);
        yTransImg(:,ix) = interp1(yRange, ir(yRange,x),yInterpRange+yCenters(ix));
    end
    yTrans = mean(yTransImg,2);
    [fitCurve,~,~, rise, sigm_params] = fitting.riseFitting(yTrans);
    width = rise / 4;
end


