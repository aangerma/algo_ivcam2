
load('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedData\regularCB_00.mat');
I = d.i;
k = d.z;
r = 1/9; % Diagonal distance to take values from
[p,bsz] = detectCheckerboardPoints(normByMax(I)); % p - 3 checkerboard points. bsz - checkerboard dimensions.

pgrid = reshape(p,[bsz-1,2]);

pPadded = zeros([bsz+1,2]);
pPadded(2:end-1,2:end-1,:) = pgrid;

% Left and Right margins 
pPadded(:,1,:) =  pPadded(:,2,:)*2 - pPadded(:,3,:);
pPadded(:,end,:) =  pPadded(:,end-1,:)*2 - pPadded(:,end-2,:);

% Top and bottom:
pPadded(1,:,:) =  pPadded(2,:,:)*2 - pPadded(3,:,:);
pPadded(end,:,:) =  pPadded(end-1,:,:)*2 - pPadded(end-2,:,:);

% Left and Right margins 
pPadded(:,1,:) =  pPadded(:,2,:)*2 - pPadded(:,3,:);
pPadded(:,end,:) =  pPadded(:,end-1,:)*2 - pPadded(:,end-2,:);

% Show the points grid
% xy = reshape(p,[],2);
% xypad = reshape(pPadded,[],2);
% plot(xypad(:,1),xypad(:,2),'go')
% hold on
% plot(xy(:,1),xy(:,2),'r*')

% I assume that the top left square is white. That means that for the first
% corner, we should grab values from right and down, and from up and left.
whiteMap = toeplitz(mod(1:max(bsz(1)-1,bsz(2)-1),2));
whiteMap = whiteMap(1:bsz(1)-1,1:bsz(2)-1);

whitePointsPerCorner = zeros(bsz(1)-1,bsz(2)-1,4);

for row = 1:bsz(1)-1
    for col = 1:bsz(2)-1
        padrow = row+1; padcol = col+1;
        % Take a ratio of r at the direction of two diagonals.
        if whiteMap(row,col)
            whitePointsPerCorner(row,col,:) = cat(3,(1-r)*pPadded(padrow,padcol,:) +(r)*pPadded(padrow-1,padcol-1,:),...
                                               (1-r)*pPadded(padrow,padcol,:) +(r)*pPadded(padrow+1,padcol+1,:));
        else
            whitePointsPerCorner(row,col,:) = cat(3,(1-r)*pPadded(padrow,padcol,:) +(r)*pPadded(padrow-1,padcol+1,:),...
                                               (1-r)*pPadded(padrow,padcol,:) +(r)*pPadded(padrow+1,padcol-1,:));
        end
        
    end
end

whitePointsPerCorner = uint16(round(whitePointsPerCorner));
% Show white points per corner:
% xywh = reshape(whitePointsPerCorner,[],4);
% tabplot;
% imagesc(I);
% hold on;
% plot(xywh(:,1),xywh(:,2),'ro')
% hold on
% plot(xywh(:,3),xywh(:,4),'ro')

N = 3;
% For each corner - get the 3x3 neighbourhoods per white point:
imv = reshape(k(Utils.indx2col(size(I),[N N])),[N^2,size(I)]);

pixelsPerCorner = zeros([bsz-1,2*N^2]);
for row = 1:bsz(1)-1
    for col = 1:bsz(2)-1
        pixelsPerCorner(row,col,:) = ...
            [squeeze(imv(:,whitePointsPerCorner(row,col,2),whitePointsPerCorner(row,col,1)));...
            squeeze(imv(:,whitePointsPerCorner(row,col,4),whitePointsPerCorner(row,col,3)))];
        
    end
end
pixelsPerCorner = sort(pixelsPerCorner,3);
kAtPoints = mean(pixelsPerCorner(:,:,end/2-1:end/2+2),3);



%%
[yg,xg]=ndgrid(0:size(I,1)-1,0:size(I,2)-1);
it = @(k2) interp2(xg,yg,k2,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.
zvalsCorners = it(k);


plot3(pgrid(:,:,1),pgrid(:,:,2),kAtPoints,'r*','DisplayName','From White')
hold on
plot3(pgrid(:,:,1),pgrid(:,:,2),zvalsCorners,'g*','DisplayName','From Corners')
title('3D points when looking at corners and at white points')
legend('show')