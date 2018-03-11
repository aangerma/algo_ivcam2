function [ blackSquares,blackCorners, blackCenters, whiteSquares,whiteCorners,whiteCenters ] = getCBSquares( I )
% detects the black and white squares in the target image and returns for
% each an Nx8 matrix where N is the number of squares and 8 is the x and y
% cordiantes for its four corners. It also return blackCorners, which is a
% 4N by 2 matrix which contains the xy coordinates of black points which
% are located at 1/8 of the diagonal. 
% Also returns an Nx2 matrix of the center location of the squares.
[p,bsz] = detectCB(I);

pmat = reshape(p,[bsz-1,2]);
rows = bsz(1)-1; cols = bsz(2)-1;
% convert each square to a 1x8 vector that has the xy of the 4 corners.
pPerSq = cat(3,pmat(1:rows-1,1:cols-1,:),...
                 pmat(1:rows-1,(1:cols-1)+1,:),...
                 pmat((1:rows-1)+1,1:cols-1,:),...
                 pmat((1:rows-1)+1,(1:cols-1)+1,:));
squares = reshape(pPerSq,[(rows-1)*(cols-1),8]);

% The color of the first square defines the color of the rest. Identify
% if it is black or white.
indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = indOneColor(1:rows-1,1:cols-1);
oddSquares = squares(logical(indOneColor(:)),:);
evenSquares = squares(logical(1-indOneColor(:)),:);
ccOdd = mean(centerColor(I,oddSquares));
ccEven = mean(centerColor(I,evenSquares));

% We assume that the left upperboard corner in the image is white, and
% below it is the darkest black square. If not, rotate\flip the image os it
% is.

if ccOdd > ccEven 
    blackSquares=evenSquares;
    whiteSquares=oddSquares;
else
    blackSquares=oddSquares;
    whiteSquares=evenSquares;
    % If we got here, it means the top left square is black, we shall flip
    % the image left right. Also, we shall flip the cordinates of the
    % squares.
    I = fliplr(I);
    whiteSquares(:,1:2:end) = size(I,2) + 1 - whiteSquares(:,1:2:end);
    blackSquares(:,1:2:end) = size(I,2) + 1 - blackSquares(:,1:2:end);
end
% Get the center points and colors of the circles that lies inside the black squares:
H = fspecial('disk',4);
If = imfilter(I,H); 
ccBlack = centerColor(If,blackSquares);
% Use the predefined order to get the sorted (by albedo) values.
ord = [1,2,3,4,12,20,28,36,44,48,47,46,45,37,29,21,13,5,6,7,8,16,24,32,40,43,42,41,33,25,17,9,10,11,19,27,35,39,38,30,22,14,15,23,31,34,26,18];
ccBlack = ccBlack(ord);
% In case The board is rotated by 180, we should see it by nonsense we see
% at the ccBlack. 
if mean(ccBlack(1:9)) > mean(ccBlack(10:18))
    I = rot90(I,2);
    % Calc squares again
    whiteSquares(:,1:2:end) = size(I,2) + 1 - whiteSquares(:,1:2:end);
    blackSquares(:,1:2:end) = size(I,2) + 1 - blackSquares(:,1:2:end);
    whiteSquares(:,2:2:end) = size(I,1) + 1 - whiteSquares(:,2:2:end);
    blackSquares(:,2:2:end) = size(I,1) + 1 - blackSquares(:,2:2:end);
    ccBlack = centerColor(rot90(If,2),blackSquares);
    % Use the predefined order to get the sorted (by albedo) values.
    ccBlack = ccBlack(ord);
    assert(mean(ccBlack(1:9)) > mean(ccBlack(10:18)),'Center circle IR values does not make sense');
end


% Use points that lies outside the circles: 
r = 1/8;
whiteCorners = [(1-r)*whiteSquares(:,1:2) + (r)*whiteSquares(:,7:8);
                (r)*whiteSquares(:,1:2) + (1-r)*whiteSquares(:,7:8);
                (1-r)*whiteSquares(:,3:4) + (r)*whiteSquares(:,5:6);
                (r)*whiteSquares(:,3:4) + (1-r)*whiteSquares(:,5:6)];
whiteCenters = (0.5)*whiteSquares(:,1:2) + (0.5)*whiteSquares(:,7:8);
blackCorners = [(1-r)*blackSquares(:,1:2) + (r)*blackSquares(:,7:8);
                (r)*blackSquares(:,1:2) + (1-r)*blackSquares(:,7:8);
                (1-r)*blackSquares(:,3:4) + (r)*blackSquares(:,5:6);
                (r)*blackSquares(:,3:4) + (1-r)*blackSquares(:,5:6);];
blackCenters = (0.5)*blackSquares(:,1:2) + (0.5)*blackSquares(:,7:8);



end
function [p,bsz] = detectCB(I)
[p,bsz] = detectCheckerboardPoints(normByMax(I)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
%Maybe there is a problem with the function that detects checkerboard
%points, give it another shot.
if (size(p,1)~=9*13)
    B = I; B(I>80) = 255;
    [p,bsz] = detectCheckerboardPoints(normByMax(B)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
end
assert(size(p,1)==9*13,'Can not detect all checkerboard corners');
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
