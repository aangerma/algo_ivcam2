function [e,ptsOut]=evalGeometricDistortion(p,verbose)
%%
tileSizeMM = 30;
h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(p,[],3)';



    %find best plane
    [mdl,d,in]=planeFit(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),[],200);
    if(nnz(in)/numel(in)<.90)
        e=1e3;
        ptsOut=xyzmes;
        return;
    end
    pvc=xyzmes-mean(xyzmes(:,in),2);
%     
    %project all point to plane
    pvp=pvc(:,in)-mdl(1:3).*d(:,in);
    
    pvp=pvp-mean(pvp,2);
    %shift to center, find rotation along PCA
    [u,~,vt]=svd(pvp*ptsOpt(:,in)');
    rotmat=u*vt';
    
    ptsOptR = rotmat*ptsOpt;
    
    errVec = vec(sqrt((sum((pvc-ptsOptR).^2))));
    if(exist('verbose','var') && verbose)
   
    plot3(pvc(1,in),pvc(2,in),pvc(3,in),'go',pvc(1,~in),pvc(2,~in),pvc(3,~in),'Ro',ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),'b+')
%     quiver3(ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),xyzmes(1,in)-ptsOptR(1,in),xyzmes(2,in)-ptsOptR(2,in),xyzmes(3,in)-ptsOptR(3,in),0)
%     plotPlane(mdl);
%     plot3(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),'ro',ptsOptR(1,:),ptsOptR(2,:),ptsOptR(3,:),'g.');
    end

 e = sqrt((mean(errVec(in).^2)));
%  e=prctile(errVec,85);
ptsOut = reshape(ptsOptR'+mean(xyzmes(:,in),2)',size(p,1),size(p,2),3);
end
