function [ newI,oldV,newV,blackwhite ] = correctCheckerboard( I, varargin )

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
% Use 5x5 median filtering to reduce the change we sample a specific point
% which is very noisy.
Imed = medfilt2(I,[5 5]);
values = interp2(1:size(I,2),1:size(I,1),single(Imed),allPoints(:,1),allPoints(:,2));

if nargin >= 2
    minVal = varargin{1}(1);
    maxVal = varargin{1}(2);
else nargin == 3
    minVal = min(values(end-size(blackPoints,1)+1:end));
    maxVal = max(values);
end
blackwhite = [minVal,maxVal];
xyv = [allPoints,values];
desiredV = [maxVal*ones(size(whitePoints,1),1);minVal*ones(size(blackPoints,1),1)];

% Get a thin plate spline model for the transformation
tps=TPS(xyv,desiredV);
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

