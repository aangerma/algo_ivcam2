function ret = calibratorOpticalMeritFunction(r,th,retErrdata)
    
    if(any(th(1:2)<0) || any(th(3:4)<-1) || any(th(3:4)>1))
        ret = 1e3;
        return;
    end
    
    aspctrto = th(1)/th(2);
    if(aspctrto>2 || aspctrto<.5)
        ret = 1e3;
        return;
    end
   
    
    [x,y,z]=Pipe.DEST.rImgUnproject(r,th(1),th(2),th(3),th(4));
      
     [d,abcd]=ransacPlane(x,y,z);  
%      [abcd,d] = planeFit(x,y,z);
    

thr = prctile(d(:),75);
    msk = d<thr;
    d(~msk)=nan;
    abcd=abcd/sqrt(sum(abcd(1:3).^2));

        switch(retErrdata)
            case 'f'
        ret = sqrt(mean(d(~isnan(d)).^2));
            case'x'
        ret=abs(abcd(1));
            case 'y'
        ret=abs(abcd(2));
            case 'v'
                plot3(x(msk),y(msk),z(msk),'.')
                 plotPlane(abcd);
                 title(abcd);
                 axis equal;axis vis3d;
                drawnow;
                ret = abcd;
        end
    fprintf('FOV (%.2f %.2f) KST(%.2f %.2f) ERR(%f)\n',[th ret]);
    
end


function [d,bestModel]=ransacPlane(x,y,z)
N_ITER = 200;
    rng(1);
    p=[x(:) y(:) z(:)];
    p(z(:)==0 | isnan(z(:)),:)=[];
    
        bestModel=[0 0 0 0];
        d=nan(size(x));
    if(size(p,1)<10)
        return;
    end
    n = size(p,1);
    bestNinlier=0;
    
    thr = 10;
    for i=1:N_ITER
        h=p(randperm(n,3),:);
        A = [h(:,1:2) ones(3,1)];
        if(abs(det(A))<1e-1)
            continue;
        end
        th = A\h(:,3);
        e = abs(p(:,1:2)*th(1:2)+th(3)-p(:,3));
        thisNinliers = nnz(e<thr);
        if(bestNinlier<thisNinliers )
            bestNinlier=thisNinliers ;
            bestModel = th;
        end
        
    end
    e = abs(p(:,1:2)*bestModel(1:2)+bestModel(3)-p(:,3));
    A2 = [p(e<thr,1:2) ones(nnz(e<thr),1)];

    bestModel = A2\p(e<thr,3);
    e = ([x(:) y(:)]*bestModel(1:2)+bestModel(3)-z(:));
    d=reshape(e,size(x));
    
    bestModel = [bestModel(1) bestModel(2) -1 bestModel(3)] ;
end
