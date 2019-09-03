function [ isLeft, isTop] = detectCBOrientation(IR, runParams  )
%% This function identifies the black circle in the middle of one of the white squares. It also looks at the neighbouring white squares for the gray circle.
% isLeft and isTop refers to the location of the gray circle in respect to
% the black circle.

[whiteSquares, ~,~,pPerSq,indOneColor] = GetSquaresCorners(IR);



% Mark and plot the color of the color in each white sqaure:
h = fspecial('disk',2);
IRFilt = imfilter(IR,h,'replicate');
whiteCenters = centerColor(IRFilt,whiteSquares);
[~,indices] = sort(whiteCenters);
chosenI = indices(1);

[i,j] = find(indOneColor);
row = i(chosenI); col = j(chosenI);
targetRows = row + [-1;-1; 1; 1];
targetCols = col + [-1; 1;-1; 1];


targetSquares = squeeze([pPerSq(targetRows(1),targetCols(1),:);
           pPerSq(targetRows(2),targetCols(2),:);
           pPerSq(targetRows(3),targetCols(3),:);
           pPerSq(targetRows(4),targetCols(4),:)]);
cc = centerColor(IRFilt,targetSquares);
[~,minI] = min(cc);
isLeft = targetCols(minI) < col;
isTop = targetRows(minI) < row;

ff = Calibration.aux.invisibleFigure;
imagesc(IR);
hold on;
viscircles(centerPoints(pPerSq(row,col,:)), 7,'Color','b');
hold on;
viscircles(centerPoints(pPerSq(targetRows(minI) ,targetCols(minI),:)), 7,'Color','r');
title('Scan Dir Image - Blue:Black Circle, Red: Gray Circle'); colormap gray;colorbar;
Calibration.aux.saveFigureAsImage(ff,runParams,'PreCalibValidation','ScanDir');


end

function [whiteSquares, blackSquares,topLeftIsWhite,pPerSq,indOneColor] = GetSquaresCorners(I)

%find CB points
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = Validation.aux.findCheckerboard(I, []); % p - 3 checkerboard points. bsz - checkerboard dimensions.


pmat = reshape(p,[bsz,2]);

rows = bsz(1); cols = bsz(2);
pPerSq = cat(3,pmat(1:rows-1,1:cols-1,:),...
                 pmat(1:rows-1,(1:cols-1)+1,:),...
                 pmat((1:rows-1)+1,1:cols-1,:),...
                 pmat((1:rows-1)+1,(1:cols-1)+1,:));
squares = reshape(pPerSq,[(rows-1)*(cols-1),8]);

indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = indOneColor(1:rows-1,1:cols-1);

oddSquares = squares(logical(indOneColor(:)),:);
evenSquares = squares(logical(1-indOneColor(:)),:);



ccOdd = mean(centerColor(I,oddSquares));
ccEven = mean(centerColor(I,evenSquares));

topLeftIsWhite = ccOdd > ccEven;
if topLeftIsWhite
    blackSquares=evenSquares;
    whiteSquares=oddSquares;
else
    blackSquares=oddSquares;
    whiteSquares=evenSquares;
    indOneColor = ~indOneColor;
end


end


function cc = centerColor(I,squares)
% returns the center color per square (format of nSquaresx8)
 cP = centerPoints(squares);
 cc = interp2(1:size(I,2),1:size(I,1),single(I),cP(:,1),cP(:,2));
end
function cP = centerPoints(squares)
% returns the center location of each square (format of nSquaresx8)
cP = [mean(squares(:,1:2:end),2),mean(squares(:,2:2:end),2)];
end