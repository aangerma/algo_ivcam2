function s = planeFitMetric(d,kmat,z2mm)
    warning('off','vision:calibrate:boardShouldBeAsymmetric')
    p=Calibration.getTargetParams();
    
    ir = normByMax(d.i);
    [c,bsz]=detectCheckerboardPoints(ir);
    bsz=bsz-1;
    if(~isequal(bsz,[p.cornersY p.cornersX]))
        error('Bad target/could not find board');
    end
    
    i=convhull(c(:,1),c(:,2));
    msk=poly2mask(c(i,1),c(i,2),size(ir,1),size(ir,2));
    mskW=imerode(ir>graythresh(ir(msk)),ones(10))&msk;
    vim = double(Pipe.z16toVerts(d.z,kmat,z2mm));
    mx=max(max(vim,[],1),[],2);
    mn=min(min(vim,[],1),[],2);
    scl = mean(2./(mx-mn));
    vim=(vim-mn).*scl-1;
    vall=reshape(vim,[],3);
    v=vall(msk,:);
    [in,mdl]=ransac(v,@gPlaneModel,@gPlaneError,'nModelPoints',5,'errorThr',1*scl);
    
    
    
    
    
    [oy,ox]=ndgrid(linspace(-1,1,bsz(1))*(bsz(1)-1)*p.mmPerUnitY,linspace(-1,1,bsz(2))*(bsz(2)-1)*p.mmPerUnitX);
    ptsOpt = [ox(:) oy(:) zeros(bsz(1)*bsz(2),1)];
    [iy,ix]=ndgrid(1:size(ir,1),1:size(ir,2));
    vsample=@(I) interp2(ix,iy,vim(:,:,I),c(:,1),c(:,2));
    distMat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
     xyzmes=[vsample(1) vsample(2) vsample(3)];
    emat=abs(distMat(xyzmes'/scl)-distMat(ptsOpt'));

    
    if(0)
        %%
        [yg,xg] = ndgrid(linspace(min(v(:,2)),max(v(:,2)),100),linspace(min(v(:,1)),max(v(:,1)),100));%#ok
        zg = reshape(qMat([xg(:) yg(:)])*mdl,size(yg));
        plot3(v(~in,1)/scl,v(~in,2)/scl,v(~in,3)/scl,'r.',v(in,1)/scl,v(in,2)/scl,v(in,3)/scl,'g.');
        surface(xg/scl,yg/scl,zg/scl,'edgecolor','none','facecolor','b','facealpha',0.2);
        hold on;plot3(xyzmes(:,1)/scl,xyzmes(:,2)/scl,xyzmes(:,3)/scl,'+b');hold off
         axis square
grid on
    end
    eim = reshape(qMat(vall)*mdl-vall(:,3),size(ir))/scl;
    s.xcurve=mdl(1)*scl;
    s.ycurve=mdl(2)*scl;
    s.std = std(eim(msk));
    s.stdW = std(eim(mskW));
    s.fillfactor=nnz(ir(msk)~=0)/nnz(msk);
    s.geomtricError=rms(emat(:));
    
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