function [hError, checkerPoints] = edgeUnifomity(ir,tunnelWidth,horizontalMargin)
EXPECTED_BOARD_SIZE=[10 14];
[imagePoints,boardSize] = detectCheckerboardPoints(ir);
if(~all(boardSize==EXPECTED_BOARD_SIZE))
    error('Bad binput image/board size');
end
checkerPoints.x=reshape(imagePoints(:,1),boardSize-1);
checkerPoints.y=reshape(imagePoints(:,2),boardSize-1);


if(0)
    
    imagesc(ir); %#ok
    hold on;plot(checkerPoints.x+1j*checkerPoints.y,'ro');hold off
    arrayfun(@(i) text(checkerPoints.x(i),checkerPoints.y(i),num2str(i)),1:numel(checkerPoints.x));
end


if(~exist('tunnelWidth','var'))
    tunnelWidth=floor(mean(vec(diff(checkerPoints.y)))/4);
end
if(~exist('horizontalMargin','var'))
    horizontalMargin=3;
end
checkerPoints.x=round(checkerPoints.x); %we are looking at scan lines - do not interp from neighbors

[yg,xg]=ndgrid(1:size(ir,1),1:size(ir,2));
hError = zeros(size(checkerPoints.x,1),1);
for i = 1:boardSize(1)-1
    xv = checkerPoints.x(i,1):checkerPoints.x(i,end);
    yv=interp1(checkerPoints.x(i,:),checkerPoints.y(i,:),xv,'spline');
    irBox=cell(boardSize(2)-2,1);
    for j=1:boardSize(2)-2
        ind = find(xv==checkerPoints.x(i,j)+horizontalMargin,1):find(xv==checkerPoints.x(i,j+1)-horizontalMargin);
        xlocs = xv(ind).*ones(tunnelWidth*2+1,1);
        ylocs = yv(ind)+(-tunnelWidth:tunnelWidth)';
        irBox{j}=interp2(xg,yg,ir,xlocs,ylocs);
    end
    
    rowError = cellfun(@(im) errorFunc(im),irBox);
    rowError = mean(rowError);
    
     hError(i) = rowError;
end
hError = sqrt(mean(hError));
end

function err = errorFunc(ir)


irN=normByMax(ir);%normalize
irB=irN>graythresh(irN);%binarize
if(mean(vec(irB.*(linspace(-1,1,size(irB,1)))'))<0)
    irB=~irB;
end
irB=imclose(irB,ones(floor(size(irB,1)/4),1));%remove small gaps
zeroIfEmpty = @(x) iff(isempty(x),0,x);
c = arrayfun(@(i) zeroIfEmpty(find(irB(:,i),1)),1:size(irB));%find crossing
% err = var(c);
err = mean((c-(size(ir,1)-1)/2).^2);

end
