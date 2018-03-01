function [cpBlack,ccBlack] = DetectBlackCBPointsAndSortedValues(I)

%find CB points
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = detectCheckerboardPoints(normByMax(I)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
if (size(p,1)~=9*13)
    B = I; B(I>100) = 255;
    [p,bsz] = detectCheckerboardPoints(normByMax(B)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    assert(size(p,1)==9*13);
end




pmat = reshape(p,[bsz-1,2]);

rows = bsz(1)-1; cols = bsz(2)-1;
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

if ccOdd > ccEven 
    blackSquares=evenSquares;
else
    blackSquares=oddSquares;
end


If =  imgaussfilt(I,4);
cpBlack = centerPoints(blackSquares);
ccBlack = centerColor(If,blackSquares);

ord = [1,2,3,4,12,20,28,36,44,48,47,46,45,37,29,21,13,5,6,7,8,16,24,32,40,43,42,41,33,25,17,9,10,11,19,27,35,39,38,30,22,14,15,23,31,34,26,18];
% [~,ord] = sort(ccBlack);
% ord([1 5]) = ord([5 1]);
% ord([7 8]) = ord([8 7]);
% ord([11 13]) = ord([13 11]);
% ord([12 13]) = ord([13 12]);
% 
% ord([14 15]) = ord([15 14]);
% ord([17 18]) = ord([18 17]);


% figure
% imagesc(I)
% colormap gray
% hold on; 
% text(cpBlack(ord,1),cpBlack(ord,2),cellfun(@num2str,num2cell(1:size(cpBlack,1)),'un',0),'Color','red','FontWeight','bold');
% title('Calib Target with Internsity Order')
% figure
% plot(ccBlack(ord),'ro')
% title('Intensity per black square')

cpBlack = cpBlack(ord,:);
ccBlack = ccBlack(ord);
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

