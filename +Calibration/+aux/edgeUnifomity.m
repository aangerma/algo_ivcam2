function [err, distortionErr,checkerPoints] = edgeUnifomity(ir,tunnelWidth,horizontalMargin)
EXPECTED_BOARD_SIZE=[10 14];
ir(sum(ir(:,2:end-1),2)==0,:)=[];
warning('off','vision:calibrate:boardShouldBeAsymmetric')
[imagePoints,boardSize] = detectCheckerboardPoints(ir);
warning('on','vision:calibrate:boardShouldBeAsymmetric')
if(~all(boardSize==EXPECTED_BOARD_SIZE))
    error('Bad binput image/board size');
end
checkerPoints.x=reshape(imagePoints(:,1),boardSize-1);
checkerPoints.y=reshape(imagePoints(:,2),boardSize-1);




if(~exist('tunnelWidth','var'))
    tunnelWidth=3;
end
if(~exist('horizontalMargin','var'))
    horizontalMargin=3;
end
checkerPoints.x=round(checkerPoints.x); %we are looking at scan lines - do not interp from neighbors

[yg,xg]=ndgrid(1:size(ir,1),1:size(ir,2));

%%

xv={};
yv={};
yf={};
evy=zeros(boardSize(1)-1,1);
for i = 1:boardSize(1)-1
    %find x location, minus vertical margin
    xv{i} = setdiff(checkerPoints.x(i,1):checkerPoints.x(i,end),vec(checkerPoints.x(i,:)+(-horizontalMargin:horizontalMargin)'));
    %find checkerboard y location in these point using splin interpolation

    p=polyfit(checkerPoints.x(i,:),checkerPoints.y(i,:),2);
    yv{i}=polyval(p,xv{i});
    evy(i)=rms(polyval(p,checkerPoints.x(i,:))-checkerPoints.y(i,:));
%          yv{i}=interp1(checkerPoints.x(i,:),checkerPoints.y(i,:),xv{i},'spline');
    %mark where checkerboard is top white bottom black, and vice versa
    yf{i} = (-1)^i*interp1(checkerPoints.x(i,:),(-1).^(1:boardSize(2)-1),xv{i},'next');
    %interpolate
end
evx=zeros(boardSize(2)-1,1);
for i = 1:boardSize(2)-1
    p=polyfit(checkerPoints.y(:,i),checkerPoints.x(:,i),2);
    evx(i)=rms(polyval(p,checkerPoints.y(:,i))-checkerPoints.x(:,i));
end
xv=[xv{:}];
yv=[yv{:}];
yf=[yf{:}];
distortionErr=rms([evx;evy]);
irBox=interp2(xg,yg,ir,repmat(xv,tunnelWidth*2+1,1),yv+(-tunnelWidth:tunnelWidth)');
%inverse the checkerboard
irBox(:,yf>0)=flipud(irBox(:,yf>0));
%%
if(0)
    %%
    subplot(5,5,setdiff(1:20,5:5:25));
    imagesc(ir); %#ok
     hold on;
     plot(checkerPoints.x+1j*checkerPoints.y,'ro');
     plot(xv,yv,'g.');
     hold off
     subplot(5,5,21:24);
     imagesc(irBox);
     subplot(5,5,25);
     plot(std(irBox,[],2),1:tunnelWidth*2+1);axis tight;set(gca,'ydir','reverse');
end
err = max(std(irBox,[],2));
end

function err = errorFunc(ir)


irN=normByMax(ir);%normalize
irB=irN>graythresh(irN);%binarize
if(mean(vec(irB.*(linspace(-1,1,size(irB,1)))'))<0)
    irB=~irB;
end
irB=imclose(irB,ones(floor(size(irB,1)/4),1));%remove small gaps
zeroIfEmpty = @(x) iff(isempty(x),0,x);
c = arrayfun(@(i) zeroIfEmpty(find(irB(:,i),1)),1:size(irB,2));%find crossing
% err = var(c);
err = mean((c-(size(ir,1)-1)/2).^2);

end
