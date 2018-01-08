function [vec,distFromPlane,inliersOut] = planeFitRansac(x,y,z,fovMask,crit,verbose)
    
    if(~exist('fovMask','var') || isempty(fovMask))
        fovMask = ones(numel(x),1);
    end
    if(~exist('crit','var'))
        crit = 5;
    end
    if(~exist('verbose','var'))
        verbose = false;
    end
     
    mask = (z(:)~=0) & fovMask(:) & ~isnan(x(:)) & ~isnan(y(:)) & ~isnan(z(:));
    xc = double(x(mask));
    yc = double(y(mask));
    zc = double(z(mask));  
    if(nnz(mask)<3)
        vec=zeros(4,1);
        distFromPlane=nan(size(x));
        inliersOut=false(size(x));
        return;
    end
    A = [xc(:) yc(:) zc(:)];
    
    [inliers, ~] = ransac(A, @planeRansacEval, @planeRansacErr, 'errorThr', crit, 'iterations', 1000, 'plotFunc', 'off');
    B = A(inliers,:);
    vec = planeRansacEval(B);
    distFromPlane = reshape(planeRansacErr(vec, [x(:) y(:) z(:)]),size(x));
    if(verbose)
        plot3(x(:),y(:),z(:),'ro');
        plotPlane(vec,'edgecolor','none','facecolor','b','facealpha',.5);
    end
%     distFromPlane(~fovMask)=nan;
inliersOut=false(size(x));
f=find(mask);inliersOut(f(inliers))=true;
end

function vec = planeRansacEval(A)

    H = [A ones(size(A,1),1)];
    H(any(isnan(H),2),:)=[];
    H(any(isinf(H),2),:)=[];
    [l,~] = eig(H'*H);
    vec = l(:,1);
    
    vec = vec/sqrt(sum(vec(1:3).^2));

end

function err = planeRansacErr(vec,A)

    err = reshape([A ones(size(A,1),1)]*vec,size(A,1),1);

end

