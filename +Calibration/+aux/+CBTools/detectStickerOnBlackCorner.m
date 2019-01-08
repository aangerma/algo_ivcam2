function [ isLeft, isTop ] = detectStickerOnBlackCorner(IR  )

% IR = frame(1).i;
% figure,tabplot;imagesc(IR)
% 
% hold on 
% plot(p(:,1),p(:,2),'r*')

[~, blackSquares,topLeftIsWhite] = GetSquaresCorners(IR);
if topLeftIsWhite
   blackCornersId = [4,size(blackSquares,1)-3];
else
   blackCornersId = [1,size(blackSquares,1)];    
end
for i=1:2
  % Get the average color withing the target square. Take roi of 20% of
  % the square;
  xi = blackSquares(blackCornersId(i),[1,3,7,5]);
  yi = blackSquares(blackCornersId(i),1+[1,3,7,5]);
  rad = 1/8*0.5*(sqrt((xi(1)-xi(3))^2+(yi(1)-yi(3))^2) + sqrt((xi(2)-xi(4))^2+(yi(2)-yi(4))^2));

  [yy,xx] = ndgrid(1:size(IR,1),1:size(IR,2));
  mask = ((xx-mean(xi)).^2 + (yy-mean(yi)).^2)<rad^2;
  cc(i) = median(IR(mask));
end
% fprintf('Sticker data:\n');
% fprintf('World view - Top Right')
if topLeftIsWhite
    if cc(1)>cc(2)
        isLeft = 1;
        isTop = 0;
%        fprintf('Matlab view - Bottom Left\n');
%        fprintf('Scan Direction - Right2Left, Bottom2Top');
    else
        isLeft = 0;
        isTop = 1;
%        fprintf('Matlab view - Top Right');
%        fprintf('Scan Direction - Left2Right, Top2Bottom');
    end
else
     if cc(1)>cc(2)
        isLeft = 1;
        isTop = 1;
    else
        isLeft = 0;
        isTop = 0;
    end
end


end

function [whiteSquares, blackSquares,topLeftIsWhite] = GetSquaresCorners(I)

%find CB points
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(I)), [9,13]); % p - 3 checkerboard points. bsz - checkerboard dimensions.

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