function [blackMask,whiteMask]=CreateMaskOfSq(irImage,margins)
marginR=margins(1); % remove marginR (#) rows from checkers
marginC=margins(2); % remove marginR (#) coulmns from checkers
imageSize=size(irImage);
pts = CBTools.findCheckerboardFullMatrix(irImage,1);
[R,C,~]=size(pts);
figure,imagesc(irImage),hold on, plot(vec(pts(:,:,1)),vec(pts(:,:,2)),'*')

ROIpts=pts(marginR+1:R-marginR,marginC+1:C-marginC,:);
[RROI,CROI,~]=size(ROIpts);

scatter(vec(ROIpts(:,:,1)),vec(ROIpts(:,:,2)),'r');

% check there are no nan assertion
assert(sum(sum(isnan(ROIpts(:,:,1))))==0,'cant detect board');


inds= toeplitz(mod(1:C,2)); % black- left up corner of black
inds = inds(1:R,:);
inds=inds(1:end-1,1:end-1);
[ BinCenters] =markCirclesFullCheckers(inds); 
ROIind=BinCenters(marginR+1:R-marginR,marginC+1:C-marginC,:);
ROIind=ROIind(1:end-1,1:end-1);
ROIindVec=ROIind(:); % 1 = black
% convert each square to a 1x8 vector that has the xy of the 4 corners.
pPerSq = cat(3,ROIpts(1:RROI-1,1:CROI-1,:),...
    ROIpts(1:RROI-1,(1:CROI-1)+1,:),...
    ROIpts((1:RROI-1)+1,(1:CROI-1)+1,:),...
    ROIpts((1:RROI-1)+1,1:CROI-1,:));
squares = reshape(pPerSq,[(RROI-1)*(CROI-1),8]);

blackSquers=squares(logical(ROIindVec==1),:);
whiteSquers=squares(logical(ROIindVec==0),:);

blackMask=zeros(imageSize); whiteMask=zeros(imageSize);

for i=1:max(size(blackSquers,1),size(whiteSquers,1))
    if(i<=size(blackSquers,1))
        x=blackSquers(i,1:2:end); y=blackSquers(i,2:2:end);
        dx=ceil(0.15*abs(round(mean([x(1),x(4)])-mean([x(2),x(3)])))); % remove checkers lines
        deltax=[dx , -dx, -dx,dx];
        dy=ceil(0.15*abs(round(mean([y(1),y(2)])-mean([y(3),y(4)]))));
        deltay=[dy , dy, -dy,-dy];
        blackMask=blackMask+poly2mask(x+deltax,y+deltay,imageSize(1),imageSize(2));
    end
    if(i<size(whiteSquers,1))
        whiteMask=whiteMask+poly2mask(whiteSquers(i,1:2:end),whiteSquers(i,2:2:end),imageSize(1),imageSize(2));
    end
end
blackMask(blackMask==0)=nan; whiteMask(whiteMask==0)=nan;

im1=double(irImage).*blackMask;
figure(); imagesc(im1);
im2=double(irImage).*whiteMask;
figure(); imagesc(im2);
end


function [ BinCenters] =markCirclesFullCheckers(BinCenters)
%1=black %0= white % 2=circle
row=8; col=8;
for d=0:4
    BinCenters(row-d:2:row+d,col+d)=2;
end
col=col+d;
for i=1:4
    BinCenters(row+i-d:2:row+i+d,col+i)=2;
end
col=col+i;
row=row+i; 

for k=[3,2,1,0]
    col=col+1; 
        BinCenters(row-k:2:row+k,col)=2;
end
end