function [ gridPointsFull,colorsMapFull ] = findCheckerboardFullMatrix( ir,imageRotatedBy180 ,isRgbImage,cornersDetectionThreshold, nonRectangleFlag, robustifyFlag)
%FINDCHECKERBOARDFULLMATRIX detects the calibration chart with the black circle within the white square as an anchor.
% Gets an IR image of the checkerboard
% Returns a 20x28x2 matrix where the last 2 dimensions are the xy location
% of each corner. Corners we where unable to detect are filled with nans.
% Make sure the image is world oriented

if ~exist('imageRotatedBy180','var')
    imageRotatedBy180 = 0;
end 
if ~exist('cornersDetectionThreshold','var') || isempty(cornersDetectionThreshold)
    if exist('isRgbImage','var') && ~isempty(isRgbImage) && isRgbImage
        cornersDetectionThreshold = 0.2; 
    else
        cornersDetectionThreshold = 0.25;
    end
end
if(~exist('nonRectangleFlag','var') || isempty(nonRectangleFlag))
    nonRectangleFlag=false;
end
if ~exist('robustifyFlag', 'var')
    robustifyFlag = false;
end
if imageRotatedBy180
    ir = rot90(ir,2);
end

[gridPointsFull,colorsMapFull] = GetSquaresCorners(ir,cornersDetectionThreshold, nonRectangleFlag,robustifyFlag);

if imageRotatedBy180
    gridPointsFull = rot90(gridPointsFull,2);
    gridPointsFull(:,:,1) = 1 + size(ir,2) - gridPointsFull(:,:,1);
    gridPointsFull(:,:,2) = 1 + size(ir,1) - gridPointsFull(:,:,2);
    colorsMapFull = rot90(colorsMapFull,2);
end

% figure,imagesc(ir);
% hold on;
% plot(vec(gridPointsFull(:,:,1)),vec(gridPointsFull(:,:,2)),'r*');



end


function [gridPointsFull,colorsMapFull] = GetSquaresCorners(ir,cornersDetectionThreshold, nonRectangleFlag,robustifyFlag)

gridPointsFull = NaN(20,28,2);
colorsMapFull = NaN(20,28,1);

%find CB points
[p,bsz] = Validation.aux.findCheckerboard(ir,[],cornersDetectionThreshold, nonRectangleFlag); % p - 3 checkerboard points. bsz - checkerboard dimensions.
if all(isnan(p(:))) || (min(bsz)<=0)
    return
end

pmat = reshape(p,[bsz,2]);
rows = bsz(1); cols = bsz(2);
[colorsMap,blackCircRow,blackCircCol] = Calibration.aux.CBTools.calcCheckerColorMap(pmat,ir,robustifyFlag);

% locate the row and col of the black circle:
indicesR = (1:rows) + 9 - blackCircRow;
indicesC = (1:cols)+ 12 - blackCircCol;

if all(indicesR>0) && all(indicesR<=20) && all(indicesC>0) && all(indicesC<=28)
    gridPointsFull(indicesR,indicesC,:) = pmat;
    colorsMapFull(indicesR,indicesC,:) = colorsMap;
end



end