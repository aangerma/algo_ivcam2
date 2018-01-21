function p = findCheckerBoardCorners(im,bsz,verbose)
%{
example:
bsz=[9 13]
im = (padarray(kron(ones((bsz+1)/2),kron([1 0;0 1],ones(7))),[ 10 10 ]));

p=Utils.findCheckerBoardCorners(im,bsz,true);


%}
%%
%
if(bsz(1)>bsz(2))
    error('Checkerboard must be horizontal');
end
%% 
N_MAX_REFINE_ITER=300;
REFINE_THR=0.01;
%%
szDOG = max(3,max(round(size(im)./bsz*0.1)));
szDOG=szDOG+mod(szDOG,2)-1;
szDOG=max(szDOG,5);

%% build edge image
im(isnan(im))=0;
im_=(histeq(normByMax(double(im))));
gx=fspecial('gaussian',[szDOG szDOG],szDOG/3);
gx = [-gx zeros(szDOG,1) gx];
dx=conv2(padarray(im_,[(szDOG-1)/2 szDOG] ,'both','replicate'),gx,'valid');
dy=conv2(padarray(im_,[ szDOG (szDOG-1)/2] ,'both','replicate'),flipud(gx'),'valid');
curlz= curl(dx,dy);
curlz=abs(curlz);
curlz(isnan(curlz))=0;
[yg,xg]=ndgrid(1:size(im,1),1:size(im,2));
if(verbose)
    %%
     imagesc(im);
     hold on
    quiver(xg,yg,dx,dy);
    hold off
end

%%
pts = zeros(prod(bsz),2);
curlzBuff = curlz;
ws=watershed(-curlzBuff);
for i=1:prod(bsz)
    [y,x]=find(curlzBuff==max(curlzBuff(:)),1);
    pts(i,:)=[x y];
    mask = ws==ws(y,x);
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
     if(all(sqrt(sum(step.^2,2))<REFINE_THR))
         break;
     end
     
     
     
 end

if(verbose)
    %%
    imagesc(curlz);
    hold on;
    plot(pts(:,1),pts(:,2),'or');
    hold off
    axis equal;
end    
%% find order
arr2cmplx = @(m) m(:,1)+1j*m(:,2);
cmplx2arr=@(m) [real(m(:)) imag(m(:))];
%find convex hull
chindx=convhull(pts(:,1),pts(:,2));
vv=arr2cmplx (pts(chindx,:));
%first point is top left
vv=circshift(vv,-minind(sum(cmplx2arr(vv),2))+1);
vv(diff(abs(vv))==0)=[];
vv=vv([1:end 1]);
vt=[0;cumsum(abs(diff(vv)))];
vt=vt/vt(end);
ti=linspace(0,1,100);
src=interp1(vt,vv,ti);
%build optimal convex hull
dst=interp1(0:.25:1,arr2cmplx ([0 0 ; 1 0; 1 1;0 1;0 0].*fliplr(bsz-1)),ti);
t = TPS(cmplx2arr(src),cmplx2arr(dst));
pts_=t.at(pts);
pts_=round(pts_);
ind=sub2ind(bsz,pts_(:,2)+1,pts_(:,1)+1);
[~,ordr]=sort(ind);
p=reshape(arr2cmplx(pts(ordr,:)),bsz);

if(verbose)
    %%
    imagesc(im);
    colormap(gray(256))
    arrayfun(@(i) text(real(p(i)),imag(p(i)),num2str(i),'color','g','fontsize',14,'fontweight','bold'),1:numel(p))
    hold on;plot(p,'r+');hold off;
    
end


end
function o=optgrid(bsz)
[y,x]=ndgrid(1:bsz(1),1:bsz(2));
o=[x(:) y(:)];
end
