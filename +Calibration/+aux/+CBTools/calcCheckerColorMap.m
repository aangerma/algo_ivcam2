function [colorsMap,blackCircRow,blackCircCol] = calcCheckerColorMap(pmat,ir,robustifyFlag)

if ~exist('robustifyFlag', 'var')
    robustifyFlag = false;
end

rows = size(pmat,1); cols = size(pmat,2);
squareCenters = 0.25*(pmat(1:rows-1,1:cols-1,:)+...
                      pmat(2:rows  ,1:cols-1,:)+...
                      pmat(1:rows-1,2:cols  ,:)+...
                      pmat(2:rows  ,2:cols  ,:));

                  
indOneColor = toeplitz(mod(1:max(rows-1,cols-1),2));
indOneColor = logical(indOneColor(1:rows-1,1:cols-1));
colorsMap = toeplitz(mod(1:max(rows,cols),2));          
colorsMap = logical(colorsMap(1:rows,1:cols));    

squaresCentersList = reshape(squareCenters,[],2);
if robustifyFlag % effective for up/down images in XGA resolution
    gaussianSigma = 2; % [pixels]
    ccAllTiles = centerColor(imgaussfilt(ir, gaussianSigma), squaresCentersList); % smooth to eliminate stripes effect
    ccAllTiles = reshape(ccAllTiles, [size(squareCenters,1), size(squareCenters,2)]);
    ccDiff = NaN(size(ccAllTiles)); % differentiate to highlight black square
    ccDiff(2:end-1,2:end-1) = ccAllTiles(2:end-1,2:end-1) - (ccAllTiles(1:end-2,2:end-1)+ccAllTiles(3:end,2:end-1)+ccAllTiles(2:end-1,1:end-2)+ccAllTiles(2:end-1,3:end))/4;
    ccOdd = ccDiff(indOneColor(:));
    ccEven = ccDiff(~indOneColor(:));
else
    oddSquares = squaresCentersList(indOneColor(:),:);
    evenSquares = squaresCentersList(~indOneColor(:),:);
    ccOdd = centerColor(ir,oddSquares);
    ccEven = centerColor(ir,evenSquares);
end

topLeftIsWhite = nanmean(ccOdd) > nanmean(ccEven);
if topLeftIsWhite
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
    [~,ind] = min(ccEven);
    blackCircCol = floor(((ind-1)/(rows-1)))*2+1;
    numInDuplex = mod(ind-1,rows-1)+1;
    if numInDuplex > floor((rows-1)/2)
        blackCircCol = blackCircCol + 1;
        blackCircRow = (numInDuplex-floor((rows-1)/2))*2-1;
    else
        blackCircRow = numInDuplex*2;
    end
    colorsMap = ~colorsMap;
end

end

function cc = centerColor(I,cP)
% returns the center color per square (format of nSquaresx8)
 cc = interp2(1:size(I,2),1:size(I,1),single(I),cP(:,1),cP(:,2));
end

