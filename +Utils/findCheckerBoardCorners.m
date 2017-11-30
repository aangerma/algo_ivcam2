function p = findCheckerBoardCorners(im,bsz,verbose)
DOG_SZ = 25;
CURL_THR = 0.5;
%% build edge image
im(isnan(im))=0;
im_=histeq(im);
g=fspecial('gaussian',[1 1]*DOG_SZ,DOG_SZ/3);
dx=conv2(im_,[-g g],'same');
dy=conv2(im_,[g;-g],'same');
curlz= curl(dx,dy);
curlz=abs(curlz);
curlz(isnan(curlz))=0;
imagesc(curlz);
%% find points
cbin=normByMax(curlz)>CURL_THR;
[bw,n]=bwlabel(cbin);
[yg,xg]=ndgrid(1:size(im,1),1:size(im,2));
msk2cmplx = @(w) sum(vec(xg.*w))+1j*sum(vec(yg.*w));
nrmMat = @(m) m/sum(m(:));
c=arrayfun(@(i) msk2cmplx(nrmMat(curlz.*(bw==i))),1:n);
if(verbose)
    imagesc(im_);
    hold on;
    plot(c,'r+');
    hold off;
end
%% align
v = [real(c);imag(c)];
nn =mean(v,2);

% [u,s,~]=svd(v*v');

 cc = v-nn;
if(verbose)
plot(cc(1,:),cc(2,:),'ro');axis equal;
end
%%
cc_=cc;
xmodels=zeros(3,bsz(1));
for i=1:bsz(1)
    if(size(cc_,2)<4)
        return;
    end
    [bestInliers,bestModel]=ransac([cc_;ones(1,size(cc_,2))]',@(x) generateLSH(x(:,1),2)\x(:,2),@(t,x) abs(generateLSH(x(:,1),2)*t-x(:,2)),'errorThr',1,'plotFunc','off');
    
    xmodels(:,i)=bestModel;
    cc_(:,bestInliers)=[];
end

cc_=cc;
ymodels=zeros(3,bsz(2));
for i=1:bsz(2)
    
    if(size(cc_,2)<4)
        return;
    end
    [bestInliers,bestModel]=ransac([cc_;ones(1,size(cc_,2))]',@(x) generateLSH(x(:,2),2)\x(:,1),@(t,x) abs(generateLSH(x(:,2),2)*t-x(:,1)),'errorThr',1,'plotFunc','off');
    ymodels(:,i)=bestModel;
    cc_(:,bestInliers)=[];
end

xv=linspace(min(cc(1,:)),max(cc(1,:)),100)';
yv=linspace(min(cc(2,:)),max(cc(2,:)),100)';
%
[~,o]=sort(ymodels(3,:));
ymodels=ymodels(:,o);

[~,o]=sort(xmodels(3,:));
xmodels=xmodels(:,o);

if(verbose)
    plot(cc(1,:),cc(2,:),'ob',xv,generateLSH(xv,2)*xmodels,'g',generateLSH(yv,2)*ymodels,yv,'r');axis equal;
    set(gca,'xlim',xv([1 end]),'ylim',yv([1 end]))
end
%% coarse loc
p=zeros(bsz);
for x=1:bsz(1)
    for y=1:bsz(2)
        a=xmodels(1,x);b=xmodels(2,x);c=xmodels(3,x);
        d=ymodels(1,y);e=ymodels(2,y);f=ymodels(3,y);
        xs=roots([a^2*d  2*a*b*d  (2*a*c*d + a*e + b^2*d) + (2*b*c*d + b*e - 1)  c^2*d + c*e + f]);
        xs=xs(imag(xs)==0 & xs+nn(1)>0 & xs+nn(1)<size(im,2));
        if(length(xs)~=1)
            continue;
        end
        
        ys = [xs*xs xs 1]*xmodels(:,x);
        p(x,y)=xs+1j*ys;
    end
end
p=[real(p(:)) imag(p(:))]'+nn;
p=reshape(p(1,:)+1j*p(2,:),bsz);
if(verbose)
    imagesc(im);
    hold on
    plot(p,'r+');
    hold off;
    axis equal;
end
%%
%%grad step to max
[cdx,cdy]=gradient(curlz);
cd_=cdx+1j*cdy;
while(true)
    pd_=interp2(xg,yg,cd_,real(p),imag(p));
    p=p+pd_*100;
    
    
    if(all(abs(pd_(:))<0.001))
        break;
    end
end

if(verbose)
    imagesc(im);
    hold on
    plot(p,'+r');
    hold off;
      axis equal;
end
