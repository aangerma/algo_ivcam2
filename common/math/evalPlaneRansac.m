function [vec,distFromPlane,inliers] = evalPlaneRansac(x,y,z,fovMask,crit)
    
    if(~exist('fovMask','var') || isempty(fovMask))
        fovMask = ones(numel(x),1);
    end
    if(~exist('crit','var'))
        crit = 5;
    end
     
    mask = (z(:)~=0) & fovMask & ~isnan(x(:)) & ~isnan(y(:)) & ~isnan(z(:));
    xc = double(x(mask));
    yc = double(y(mask));
    zc = double(z(mask));  
    A = [xc(:) yc(:) zc(:)];
    
    [inliers, ~] = ransac(A, @planeRansacEval, @planeRansacErr, 'errorThr', crit, 'iterations', 1000, 'plotFunc', 'off');
    B = A(inliers,:);
    vec = planeRansacEval(B);
    distFromPlane = planeRansacErr(vec, B);
    
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

