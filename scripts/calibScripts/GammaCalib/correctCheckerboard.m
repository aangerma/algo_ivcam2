function [ newI,oldV,newV ] = correctCheckerboard( I )
% Identify Checkerboard and mitigates vignneting(only on the CB)
[whiteSquares,blackSquares] = GetSquaresCorners(I);
r = 1/8;
whitePoints = [(1-r)*whiteSquares(:,1:2) + (r)*whiteSquares(:,7:8);
                (r)*whiteSquares(:,1:2) + (1-r)*whiteSquares(:,7:8);
                (1-r)*whiteSquares(:,3:4) + (r)*whiteSquares(:,5:6);
                (r)*whiteSquares(:,3:4) + (1-r)*whiteSquares(:,5:6);
                (0.5)*whiteSquares(:,1:2) + (0.5)*whiteSquares(:,7:8)];
                
blackPoints = [(1-r)*blackSquares(:,1:2) + (r)*blackSquares(:,7:8);
                (r)*blackSquares(:,1:2) + (1-r)*blackSquares(:,7:8);
                (1-r)*blackSquares(:,3:4) + (r)*blackSquares(:,5:6);
                (r)*blackSquares(:,3:4) + (1-r)*blackSquares(:,5:6);];
            
                
                
% imshow(I); 
% hold on;plot(whitePoints(:,1),whitePoints(:,2),'ro')
% hold on;plot(blackPoints(:,1),blackPoints(:,2),'go')

% For each point, get the corresponding value from the image
allPoints = [whitePoints;blackPoints];
values = interp2(1:size(I,2),1:size(I,1),single(I),allPoints(:,1),allPoints(:,2));

xyv = [allPoints,values];
desiredV = [max(values)*ones(size(whitePoints,1),1);min(values)*ones(size(blackPoints,1),1)];

% Get a thin plate spline model for the transformation
tps=TPS2(xyv,desiredV);
% Apply the transformation on the image grid.
whiteCorners = [whiteSquares(:,1:2);whiteSquares(:,3:4);whiteSquares(:,5:6);whiteSquares(:,7:8)];
blackCorners = [blackSquares(:,1:2);blackSquares(:,3:4);blackSquares(:,5:6);blackSquares(:,7:8)];
minXY = floor(min([whiteCorners;blackCorners]));
maxXY = ceil(max([whiteCorners;blackCorners]));
[gy,gx] = ndgrid(minXY(2):maxXY(2),minXY(1):maxXY(1)  );
v = I(minXY(2):maxXY(2),minXY(1):maxXY(1));
inputPoints = [gx(:),gy(:),single(v(:))];
undist=tps.at(inputPoints);
oldV = v;
newV = reshape(uint8(undist),size(v));
newI = I;
newI(minXY(2):maxXY(2),minXY(1):maxXY(1)) = newV;
end

