function [vec ,distFromPlane,fovMaskOut] = planeFit(x,y,z,fovMask,outliersThr)

    if(~exist('fovMask','var') || isempty(fovMask))
        fovMask = ones(numel(x),1);
    end
    if(~exist('outliersThr','var'))
        outliersThr = 75;
    end
    
    if(numel(x)<10)
        vec=zeros(4,1);
        distFromPlane=zeros(size(x));
        fovMaskOut=fovMask;
        return;
    end
    
    mask = (z(:)~=0) & fovMask(:) & ~isnan(x(:)) & ~isnan(y(:)) & ~isnan(z(:));
    [yg,xg]=ndgrid(1:size(mask,1),1:size(mask,2));
    yg = yg(mask);
    xg = xg(mask);
    xc=double(x(mask));
    yc=double(y(mask));
    zc=double(z(mask));
    H = [xc yc zc ones(length(xc),1)];
    H(any(isnan(H),2),:)=[];
    H(any(isinf(H),2),:)=[];
    [l,v] = eig(H'*H);
    vec = l(:,1);
    %OUTLIERS
    err = (H*vec).^2;
    thr = prctile(err,outliersThr);
    indx = err<thr;
    H = H(indx,:);
    [l,v] = eig(H'*H);
    vec = l(:,1);
    if(vec(3)<0)
        vec = -vec;
    end
    
    vec = vec/sqrt(sum(vec(1:3).^2));
    
    distFromPlane = reshape([x(:) y(:) z(:) ones(numel(x),1)]*vec,size(x));
    
    fovMaskOut = mask;
    fovMaskOut(sub2ind(size(mask),yg(~indx),xg(~indx)))=false;
    
end