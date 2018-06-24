function s = planeFitMetric(d,kmat,z2mm)
%{
usage:
hw=HWinterface
kmat=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
z2mm=2^hw.read('GNRLzMaxsubMMExp');
d=hw.getFrame(30);
s=Validation.planeFitMetric(d,kmat,z2mm);
%}
    PLANE_FIT_ERR=1.5;

    warning('off','vision:calibrate:boardShouldBeAsymmetric')
    p=Calibration.getTargetParams();
    
    ir = normByMax(d.i);
    [c,bsz]=detectCheckerboardPoints(ir);
    bsz=bsz-1;
      if(~isequal(bsz,[p.cornersY p.cornersX]))
        error('Bad target/could not find board');
    end
 ind = [1  bsz(1)  bsz(1)*bsz(2) bsz(1)*(bsz(2)-1)+1 ];
 
    
    S = [c(ind,:) ones(4,1)];
    D = [-1 -1 ;-1 1 ;1 1 ;1 -1 ];

    % D_ = [k1;k2;k3]*S k3(3)=1; 
    %D(:,1)*k3*s=k1*s
    %D(:,2)*k3*s=k2*s
    %|-S  0 D(:,1)*s| |k1|  |0|
    %| 0 -S D(:,2)*s| |k2| =|0|
    %| 0  0 [0 0..1]| |k3|  |1|
    N=1001;
    k=reshape([-S zeros(4,3) D(:,1).*S;zeros(4,3) -S D(:,2).*S; zeros(1,8) 1]\[zeros(8,1);1],3,3)';
    [yg01,xg01]=ndgrid(linspace(-1,1,N),linspace(-1,1,N));
    XXX=(k^-1*[xg01(:) yg01(:) yg01(:)*0+1]');
    XXX=reshape((XXX(1:2,:)./XXX(3,:))',[N N ,2]);
    [yg,xg]=ndgrid(1:size(ir,1),1:size(ir,2));
    warp2board = @(im) interp2(xg,yg,im,XXX(:,:,1),XXX(:,:,2));
 
 
    
    msk=poly2mask(c(ind,1),c(ind,2),size(ir,1),size(ir,2));
    mskW=imerode(ir>graythresh(ir(msk)),ones(10))&msk;
    vim = double(Pipe.z16toVerts(d.z,kmat,z2mm));
    mx=max(max(vim,[],1),[],2);
    mn=min(min(vim,[],1),[],2);
    scl = mean(2./(mx-mn));
    
    nrm=@(x) (x-mn).*scl-1;
    dnrm =@(x) (x+1)./scl+mn;
    vim_=nrm(vim);
    vall=reshape(vim_,[],3);
    v=vall(msk,:);
    [in,mdl]=ransac(v,@gPlaneModel,@gPlaneError,'nModelPoints',5,'errorThr',PLANE_FIT_ERR*scl);
    
    
    
    
    
    [oy,ox]=ndgrid(linspace(-1,1,bsz(1))*(bsz(1)-1)*p.mmPerUnitY/2,linspace(-1,1,bsz(2))*(bsz(2)-1)*p.mmPerUnitX/2);
    ptsOpt = [ox(:) oy(:) zeros(bsz(1)*bsz(2),1)];
    [iy,ix]=ndgrid(1:size(ir,1),1:size(ir,2));
    vsample=@(I) interp2(ix,iy,vim(:,:,I),c(:,1),c(:,2));
    distMat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
    xyzmes=[vsample(1) vsample(2) vsample(3)];
    emat=abs(distMat(xyzmes')-distMat(ptsOpt'));
    
    eim = reshape(qMat(vall)*mdl-vall(:,3),size(ir))/scl;
    if(1)
        %%
%         v_=permute(dnrm(permute(v,[1 3 2])),[1 3 2]);
%         [yg,xg] = ndgrid(linspace(min(v(:,2)),max(v(:,2)),100),linspace(min(v(:,1)),max(v(:,1)),100));%#ok
%         zg = reshape(qMat([xg(:) yg(:)])*mdl,size(yg));
%         plot3(v_(~in,1),v_(~in,2),v_(~in,3),'r.',v_(in,1),v_(in,2),v_(in,3),'g.');
%         v_hat=dnrm(cat(3,xg,yg,zg));
%          surface(v_hat(:,:,1),v_hat(:,:,2),v_hat(:,:,3),'edgecolor','none','facecolor','b','facealpha',0.2);
         plot3(xyzmes(:,1),xyzmes(:,2),xyzmes(:,3),'+b','linewidth',10);
         X=cat(3,warp2board(vim(:,:,1)),warp2board(vim(:,:,2)),warp2board(vim(:,:,3)));
         surface(X(:,:,1),X(:,:,2),X(:,:,3),warp2board(abs(eim)),'edgecolor','none')
%          
%         
%          hold off
         axis square
grid on
colorbar
    end
    
    
    
    
    
    s.xcurve=mdl(1)*scl;
    s.ycurve=mdl(2)*scl;
    s.std = std(eim(msk));
    s.stdW = std(eim(mskW));
    s.fillfactor=nnz(ir(msk)~=0)/nnz(msk);
    s.geomtricError=sqrt(mean(emat(:).^2));
    s.errImg=eim;
    s.msk=msk;
    
end

function h=qMat(X)
    h=[X(:,1:2).^2 X(:,1:2) ones(size(X,1),1)];
end

function e=gPlaneError(th,X)
    h=qMat(X);
    e=abs(h*th-X(:,3));
end
function th=gPlaneModel(X)
    h=qMat(X);
    HH=h'*h;
   
    th=(HH)^-1*h'*X(:,3);
end