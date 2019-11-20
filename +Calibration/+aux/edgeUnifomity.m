function [err,cc, distortionErr] = edgeUnifomity(ir,tunnelWidth,horizontalMargin,verbose)
if(~exist('tunnelWidth','var'))
    tunnelWidth=7;
end
if(~exist('horizontalMargin','var'))
    horizontalMargin=3;
end
if(~exist('verbose','var'))
    verbose=false;
end

ir(sum(ir(:,2:end-1),2)==0,:)=[];

ir_=ir;

ir_(isnan(ir_))=0;
ir_ = histeq(normByMax(ir_));
[pt,bsz]=detectCheckerboardPoints(ir_);
 boardSize=[9 13];%bsz-1
 
if(~all(bsz-1==boardSize))
     error('Bad binput image/board size');
 end
 
 
pt=reshape(pt(:,1)+1j*pt(:,2),boardSize);






%checkerPoints.x=round(checkerPoints.x); %we are looking at scan lines - do not interp from neighbors

[yg,xg]=ndgrid(1:size(ir,1),1:size(ir,2));

%%

xv={};
yv={};
yf={};
evy=zeros(boardSize(1),1);
for i = 1:boardSize(1)
    %find x location, minus vertical margin
    xv{i} =real(pt(i,1)):.5:real(pt(i,end));
    xv{i}(min(abs(xv{i}-vec(real(pt(i,:))')))<horizontalMargin)=[];
    %find checkerboard y location in these point using splin interpolation

    p=polyfit(real(pt(i,:)),imag(pt(i,:)),2);
    yv{i}=polyval(p,xv{i});
    evy(i)=rms(polyval(p,real(pt(i,:)))-imag(pt(i,:)));
%          yv{i}=interp1(checkerPoints.x(i,:),checkerPoints.y(i,:),xv{i},'spline');
    %mark where checkerboard is top white bottom black, and vice versa
    yf{i} = (-1)^i*interp1(real(pt(i,:)),(-1).^(1:boardSize(2)),xv{i},'next');
    %interpolate
end
evx=zeros(boardSize(2),1);
for i = 1:boardSize(2)
    p=polyfit(imag(pt(:,i)),real(pt(:,i)),2);
    evx(i)=rms(polyval(p,imag(pt(:,i)))-real(pt(:,i)));
end
xv=[xv{:}];
yv=[yv{:}];
yf=[yf{:}];
distortionErr=rms([evx;evy]);
irBox=interp2(xg,yg,ir,repmat(xv,tunnelWidth*2+1,1),yv+(-tunnelWidth:tunnelWidth)');
%inverse the checkerboard
irBox(:,yf>0)=flipud(irBox(:,yf>0));
[~,dy]=gradient(irBox);
[m1,mi]=max(dy(2:end-1,:));
mi=mi+1;
m0 = dy(sub2ind(size(dy),mi-1,1:size(dy,2)));
m2 = dy(sub2ind(size(dy),mi+1,1:size(dy,2)));

ddy = diff([m0;m1;m2]);
cc = mean(ddy)./diff(ddy)+mi-(tunnelWidth+1);
err=std(cc);
%%
if(verbose)
    %%
    subplot(6,1,1:4);
    imagesc(ir_); axis equal
     hold on;
     plot(pt,'ro');
     plot(xv,yv,'g.');
     hold off
     subplot(6,1,5:6);
     imagesc(irBox,'ydata',-tunnelWidth:tunnelWidth);
     hold on
     plot(1:length(cc),cc,'r.');
     hold off
     title(std(cc));
end

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
