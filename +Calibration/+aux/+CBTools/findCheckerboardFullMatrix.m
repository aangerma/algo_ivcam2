function [ gridPointsFull ] = findCheckerboardFullMatrix( ir,imageRotatedBy180 )
%FINDCHECKERBOARDFULLMATRIX detects the calibration chart with the black circle within the white square as an anchor.
% Gets an IR image of the checkerboard
% Returns a 20x28x2 matrix where the last 2 dimensions are the xy location
% of each corner. Corners we where unable to detect are filled with nans.
% Make sure the image is world oriented

if ~exist('imageRotatedBy180','var')
    imageRotatedBy180 = 0;
end

if imageRotatedBy180
    ir = rot90(ir,2);
end

gridPointsFull = GetSquaresCorners(ir);

if imageRotatedBy180
    gridPointsFull = rot90(gridPointsFull,2);
    gridPointsFull(:,:,1) = 1 + size(ir,2) - gridPointsFull(:,:,1);
    gridPointsFull(:,:,2) = 1 + size(ir,1) - gridPointsFull(:,:,2);
    
end

% figure,imagesc(ir);
% hold on;
% plot(vec(gridPointsFull(:,:,1)),vec(gridPointsFull(:,:,2)),'r*');



end


function [gridPointsFull] = GetSquaresCorners(ir)

%find CB points

[p,bsz] = Validation.aux.findCheckerboard(ir); % p - 3 checkerboard points. bsz - checkerboard dimensions.

pmat = reshape(p,[bsz,2]);



rows = bsz(1); cols = bsz(2);
squareCenters = 0.25*(pmat(1:rows-1,1:cols-1,:)+...
                      pmat(2:rows  ,1:cols-1,:)+...
                      pmat(1:rows-1,2:cols  ,:)+...
                      pmat(2:rows  ,2:cols  ,:));

                  
indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = logical(indOneColor(1:rows-1,1:cols-1));
            
squaresCentersList = reshape(squareCenters,[],2);

oddSquares = squaresCentersList(indOneColor(:),:);
evenSquares = squaresCentersList(~indOneColor(:),:);


ccOdd = centerColor(ir,oddSquares);
ccEven = centerColor(ir,evenSquares);

topLeftIsWhite = mean(ccOdd) > mean(ccEven);
if topLeftIsWhite
    blackSquares=evenSquares;
    whiteSquares=oddSquares;
    [~,ind] = min(ccOdd);
    blackCircCol = floor(((ind-1)/(rows-1)))*2+1;
    numInDuplex = mod(ind-1,rows-1)+1;
    if numInDuplex > ceil((rows-1)/2)
        blackCircCol = blackCircCol + 1;
        blackCircRow = (numInDuplex-ceil((rows-1)/2))*2;
    else
        blackCircRow = numInDuplex*2-1;
    end
else
    blackSquares=oddSquares;
    whiteSquares=evenSquares;
    indOneColor = ~indOneColor;
    [~,ind] = min(ccEven);
    blackCircCol = floor(((ind-1)/(rows-1)))*2+1;
    numInDuplex = mod(ind-1,rows-1)+1;
    if numInDuplex > floor((rows-1)/2)
        blackCircCol = blackCircCol + 1;
        blackCircRow = (numInDuplex-floor((rows-1)/2))*2-1;
    else
        blackCircRow = numInDuplex*2;
    end
end
% figure,
% imagesc(ir);
% hold on
% plot(squareCenters(blackCircRow,blackCircCol,1),squareCenters(blackCircRow,blackCircCol,2),'go')
% locate the row and col of the black circle:
indicesR = (1:rows) + 9 - blackCircRow;
indicesC = (1:cols)+ 12 - blackCircCol;

gridPointsFull = NaN(20,28,2);
if all(indicesR>0) && all(indicesR<=20) && all(indicesC>0) && all(indicesC<=28)
    gridPointsFull(indicesR,indicesC,:) = pmat;
end

end
function cc = centerColor(I,cP)
% returns the center color per square (format of nSquaresx8)
 cc = interp2(1:size(I,2),1:size(I,1),single(I),cP(:,1),cP(:,2));
end