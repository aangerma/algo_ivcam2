function [bestLine bestInliers]=fitLineRANSAC(mat,thr,drawFig)
if(~exist('thr','var'))
    thr = 10;
end

if(~exist('drawFig','var'))
    drawFig = false;
end

n = size(mat,1);
K=1000;


if(drawFig)
    plotPoint(mat,'.b');
    aa = [];
    bb = [];
end

bestInliers = [];
bestErr = inf;
for i=1:K
    [~,seed] = sort(rand(n,1));
    x = mat(seed(1:2),1);
    y = mat(seed(1:2),2);
    maybeLine = lineABfromPTs(x,y);
    d=distFromABline(mat(:,1),mat(:,2),maybeLine);
    maybeInliers = find(d<thr);
    
    
    nx = mat(maybeInliers,1);
    ny = mat(maybeInliers,2);
    
    
    if(drawFig)
        maybeLine2 = lineABfromPTs(nx,ny);
        delete(aa);
        aa(1) = plotLine([maybeLine2(1) -1 maybeLine2(2)]','color','c');
        aa(2) = plotPoint(mat(seed(1:2),:),'co');
        drawnow;
    end
    
    if(length(maybeInliers) > length(bestInliers))
        maybeLine = lineABfromPTs(mat(maybeInliers,1),mat(maybeInliers,2));
        err = sum(abs(mat(maybeInliers,1)*maybeLine(1) +maybeLine(2) - mat(maybeInliers,2)))/length(maybeInliers);
        if(err<bestErr || 1)
            bestErr=err;
            bestInliers = maybeInliers;
            
            
            if(drawFig)
                delete(bb);
                
                bb(1) =  plotLine([maybeLine(1) -1 maybeLine(2)]','color','r');
                bb(2) = plotPoint(mat(bestInliers,:),'ro');
                title(sprintf('# inliers = %d',length(bestInliers)));
                drawnow;
            end
        end
    end
    
    
    %       plot(mat(:,1),mat(:,2),'r.');
    %        hold on
    %        plotLine([maybeLine(1) -1 maybeLine(2)],'color','b');
    %         plotLine([bestLine(1) -1 bestLine(2)],'color','g');
    %        hold off
    %        axis equal
    %
    %        drawnow;
    
end
bestLine = lineABfromPTs(mat(bestInliers,1),mat(bestInliers,2));
end

function ab = lineABfromPTs(x,y)
H = [x ones(size(x,1),1)];
% ab =(H'*H)^-1*H'*y
ab = H\y;
end

function d = distFromABline(x,y,ab)
d = abs(ab(1)*x - y + ab(2))/sqrt(ab(1)^2+1);
end
