function p = findCheckerBoardCorners(im,bsz,verbose)
%{
example:
bsz=[9 13]
im = (padarray(kron(ones((bsz+1)/2),kron([1 0;0 1],ones(7))),[ 10 10 ]));

p=Utils.findCheckerBoardCorners(im,bsz,true);

%% accuracy vs SNR test
n = [0.01:0.1:1];

[gty,gtx]=ndgrid(1:bsz(1),1:bsz(2))
pgt=(gtx*7+10.5)+1j*(gty*7+10.5)
imagesc(im);
hold on
plot(gtp,'r+');
hold off
e=zeros(size(n));
g=false(size(n));
NRAND=100;
for i=1:length(n)
    for j=1:NRAND
        rng(j)
        imN = im+rand(size(im))*n(i);
        imN = conv2(imN,fspecial('gaussian',[5 5],.5),'same');
        try
        p=Utils.findCheckerBoardCorners(imN,bsz,true);
catch
break;
end
        e(i)=e(i)+rms(p-pgt);
    end
    if(j!=NRAND)
    break;
end


%}
%%
%
if(bsz(1)>bsz(2))
    error('Checkerboard must be horizontal');
end
%% 
N_MAX_REFINE_ITER=300;
%%
szDOG = max(3,max(round(size(im)./[9 13]*0.1)));
szDOG=szDOG+mod(szDOG,2)-1;

%% build edge image
im(isnan(im))=0;
im_=histeq(normByMax(im));
gx=fspecial('gaussian',[szDOG szDOG],szDOG/3);
gx = [-gx zeros(szDOG,1) gx];
dx=conv2(padarray(im_,[(szDOG-1)/2 szDOG] ,'both','replicate'),gx,'valid');
dy=conv2(padarray(im_,[ szDOG (szDOG-1)/2] ,'both','replicate'),flipud(gx'),'valid');
curlz= curl(dx,dy);
curlz=abs(curlz);
curlz(isnan(curlz))=0;
[yg,xg]=ndgrid(1:size(im,1),1:size(im,2));
if(verbose)
     imagesc(im);
     hold on
    quiver(xg,yg,dx,dy);
    hold off
end

%%
pts = zeros(prod(bsz),2);
curlzBuff = curlz./(1+dx.*dx+dy.*dy);

for i=1:prod(bsz)
    [y,x]=find(curlzBuff==max(curlzBuff(:)),1);
    pts(i,:)=[x y];
    mask = false(size(curlzBuff));
    mask(y,x)=true;
    mask=imdilate(mask,ones(szDOG*2-1));
    curlzBuff(mask)=0;
end
% refindment step
[cdx,cdy]=gradient(curlz);
for i=1:N_MAX_REFINE_ITER

  

    
     sdx = interp2(xg,yg,cdx,pts(:,1),pts(:,2));
     sdy = interp2(xg,yg,cdy,pts(:,1),pts(:,2));
     step = [sdx sdy];
     pts=pts+step;
     
     
     %
     if(all(sqrt(sum(step.^2,2))<1e-3))
         break;
     end
     
     
     
 end

if(verbose)
    %%
    imagesc(im);
        hold on;
    plot(pts(:,1),pts(:,2),'or');
    hold off
    axis equal;
end    
%%
v = pts-mean(pts);
[u,~,~]=svd(v'*v);
rotang=angle(exp(1j*acos([1 0]*u(:,1))*2))/2;
%limit rotation to 45deg with no flipping
u=[cos(rotang) -sin(rotang);sin(rotang) cos(rotang)];

v = v*u;
% v=(v-min(v))./(max(v)-min(v)).*([bsz(2) bsz(1)]-0.01)+.5;
  v=(v-min(v))./(max(v)-min(v)).*([bsz(2) bsz(1)]-1)+1;
vI=round(v);

for i=1:3
    goodFit =  sum(abs((vI(:,1)+1j*vI(:,2))-(vI(:,1)'+1j*vI(:,2)'))==0)==1;
    vind=sub2ind(bsz,vI(:,2),vI(:,1));    
    badmap=reshape(accumarray(vind,ones(size(vI,1),1),[bsz(1)*bsz(2) 1]),bsz)~=1;
    
    if(all(badmap(:)==0))
        break;
    end
    badmap=imdilate(badmap,true(3));
    goodind=all(vind~=vec(find(badmap))',2);
    
    tt=TPS(v(goodind,:),vI(goodind,:));
    vI(~goodind,:)=round(tt.at(v(~goodind,:)));
    vI(:,1)=max(1,min(vI(:,1),bsz(2)));
    vI(:,2)=max(1,min(vI(:,2),bsz(1)));
end
if(~all(goodFit))
    if(verbose)
        plot(v(:,1),v(:,2),'+',vI(:,1),vI(:,2),'g^');
        axis equal;set(gca,'XTick',1:bsz(2)+1,'YTick',1:bsz(1)+1,'xlim',[0 bsz(2)+1],'ylim',[0 bsz(1)+1]);grid on
        hold on;
        quiver(v(:,1),v(:,2),vI(:,1)-v(:,1),vI(:,2)-v(:,2),0)
        hold off
    end
    error('bad image formation');
end

if(verbose)
    %%
    plot(v(:,1),v(:,2),'+',vI(:,1),vI(:,2),'g^');
    hold on;
    quiver(v(:,1),v(:,2),vI(:,1)-v(:,1),vI(:,2)-v(:,2),0)
    hold off
    axis equal;set(gca,'XTick',1:bsz(2)+1,'YTick',1:bsz(1)+1,'xlim',[0 bsz(2)+1],'ylim',[0 bsz(1)+1]);grid on
end

%%
vind=(sub2ind(bsz,vI(:,2),vI(:,1)));
[~,ordr]=sort(vind);
p=pts(ordr,:);
p=reshape(p(:,1)+1j*p(:,2),bsz);
if(verbose)
    %%
    imagesc(im);
    colormap(gray(256))
    arrayfun(@(i) text(real(p(i)),imag(p(i)),num2str(i),'color','g','fontsize',14,'fontweight','bold'),1:numel(p))
    hold on;plot(p,'r+');hold off;
    
end


end
