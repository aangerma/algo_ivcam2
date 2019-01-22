%configureation:checkeSize,checkersX,checkersY

% definitions
checkerSize = 30; 
targetSizeMM = [841 594];
mm2Pix = 20;
margin = 10;
halfChecker = 0;%currently half checkers not supported 
shades = 10:10:90;
numOfCircPerShade = 5;
% calculate sizes
checkerPixSize = checkerSize*mm2Pix;
checkerPixHalfSize = checkerPixSize/2;

checkersNum = floor((targetSizeMM-margin*2)/checkerSize);
extraBounderiesPix = flip(round(((((targetSizeMM-margin*2)/checkerSize) - checkersNum)*checkerSize)/2));
marginPix = margin*mm2Pix;
%create checkers
checkers = checkerboard(checkerPixSize,checkersNum(2),checkersNum(1));
checkers = checkers(1:end/2,1:end/2);


%draw circles
[xx, yy] = ndgrid(1:checkerPixSize,1:checkerPixSize);
xx = xx-mean(xx(:));yy = yy-mean(yy(:));
R = checkerPixSize*2/3/2;
circleTmplt = double(xx.^2 + yy.^2 < R.^2);


%find the black checker closest to the middle
labels =zeros(checkersNum,'logical')';
labels(2:2:end,:) = 1;
labels(:,2:2:end) = ~labels(:,2:2:end);

[xx, yy] = ndgrid(1:checkersNum(1),1:checkersNum(2));
xx = xx-mean(xx(:));yy = yy-mean(yy(:));
distanceFromMiddle = (xx.^2 + yy.^2)';

elgCheckers = zeros(checkersNum)';
elgCheckers(labels) = Inf;
elgCheckers(~labels) = distanceFromMiddle(~labels);
[mY,mX]=ind2sub(flip(checkersNum),minind(elgCheckers(:)));
middleBChecker = [mX,mY];

imagesc(checkers)
hold on
plot (size(checkers,2)/2,size(checkers,1)/2,'+r')
hold off

for sid=1:length(shades)
    currentOffset = sid-5;
    currentChecker = middleBChecker + currentOffset;
    for cid=1:numOfCircPerShade
        circOffset = cid - ceil(numOfCircPerShade/2);
        currentCircChecker = currentChecker + [-circOffset,circOffset];
        checkers((currentCircChecker(2)-1)*checkerPixSize+1:currentCircChecker(2)*checkerPixSize,(currentCircChecker(1)-1)*checkerPixSize+1:currentCircChecker(1)*checkerPixSize) =  circleTmplt * shades(sid) / 100;
    end
end

%   draw black circle
blackCircChecker = middleBChecker + [-1, -2]; %upper
checkers((blackCircChecker(2)-1)*checkerPixSize+1:blackCircChecker(2)*checkerPixSize,(blackCircChecker(1)-1)*checkerPixSize+1:blackCircChecker(1)*checkerPixSize) =  1-circleTmplt*0.6;
blackCircChecker = middleBChecker + [-2, -1]; %left
checkers((blackCircChecker(2)-1)*checkerPixSize+1:blackCircChecker(2)*checkerPixSize,(blackCircChecker(1)-1)*checkerPixSize+1:blackCircChecker(1)*checkerPixSize) =  1-circleTmplt;

%draw operator marker
rChar = str2im('R',nan,'HorizontalAlignment','center','FontSize',checkerSize);
rChar = double(rChar(:,:,1));
rChar = imresize(rChar./max(rChar(:)),[checkerPixSize/2,checkerPixSize/2],'nearest');
opMarker = ones(checkerPixSize);
opMarker(1:checkerPixSize/2,checkerPixSize/2+1:end) = max(0,min(1,rChar));
%{
opMarker =
[xx,yy] = meshgrid(linspace(0,1,checkerPixSize));
opMarker(yy<0.9 & yy>0.4 & xx<1-0.6*yy & xx>0.6*yy)=1;
opMarker = flipud(opMarker);
%}
if (labels(1,end)==0)
    opMarker = 1-opMarker;
end
checkers(1:checkerPixSize,(checkersNum(1)-1)*checkerPixSize+1:checkersNum(1)*checkerPixSize) = opMarker;


I = ones(targetSizeMM * mm2Pix)';
offs = extraBounderiesPix + marginPix ;
I(offs(1)+1: offs(1)+size(checkers,1),offs(2)+1: offs(2)+size(checkers,2)) = checkers;
imagesc(I);
colormap gray
axis image; axis off;

%save target as png
saveMatAsGrayScalePng(I,fullfile(ivcam2root,sprintf('Iv2CalibTarget%dx%dx%dmm.png',targetSizeMM(1),targetSizeMM(2),checkerSize)))

