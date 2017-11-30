function p = findCheckerBoardCorners(im,bsz,verbose)
DOG_SZ = 10;

%% build edge image
im(isnan(im))=0;
im_=histeq(normByMax(im));
g=fspecial('gaussian',[1 1]*DOG_SZ,DOG_SZ/3);
dx=conv2(im_,[-g g],'same');
dy=conv2(im_,[g;-g],'same');
curlz= curl(dx,dy);
curlz=abs(curlz);
curlz(isnan(curlz))=0;
[yg,xg]=ndgrid(1:size(im,1),1:size(im,2));
%%
binImg = curlz>prctile(curlz(:),95);
bw= bwlabel(binImg);
pts = zeros(prod(bsz),2);
curlzBuff = curlz;

for i=1:prod(bsz)
    [y,x]=find(curlzBuff==max(curlzBuff(:)));
    lblBin = bw==bw(y,x);
    nn = nnz(lblBin);
    pts(i,:)=[lblBin(:)'*xg(:) lblBin(:)'*yg(:)]/nn;
    curlzBuff(lblBin)=0;
end
%%
v = pts-mean(pts);
[u,~,~]=svd(v'*v);
u=[sign(u(1)) 0 ; 0 sign(u(4))]*u;
v = v*u;
% v=(v-min(v))./(max(v)-min(v)).*([bsz(2) bsz(1)]-0.01)+.5;
  v=(v-min(v))./(max(v)-min(v)).*([bsz(2) bsz(1)]-1)+1;
vI=round(v);

for i=1:3
    goodFit =  sum(abs((vI(:,1)+1j*vI(:,2))-(vI(:,1)'+1j*vI(:,2)'))==0)==1;
    if(all(goodFit))
        break;
    end
    tt=TPS(v(goodFit,:),vI(goodFit,:));
    vI(~goodFit,:)=round(tt.at(v(~goodFit,:)));
    vI(:,1)=min(1,max(vI(:,1),bsz(2)));
    vI(:,2)=min(1,max(vI(:,2),bsz(1)));
end
if(~all(goodFit))
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
ind=(sub2ind(bsz,vI(:,2),vI(:,1)));
[~,ordr]=sort(ind);
p=pts(ordr,:);
p=reshape(p(:,1)+1j*p(:,2),bsz);
if(verbose)
    %%
    imagesc(im)
    hold on;plot(p,'r+');hold off;
    arrayfun(@(i) text(real(p(i)),imag(p(i)),num2str(i),'color','g'),1:length(p))
end


end
