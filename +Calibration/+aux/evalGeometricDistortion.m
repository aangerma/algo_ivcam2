function [e,e_dist,ptsOut]=evalGeometricDistortion(p,verbose,tileSizeMM)
%%
if ~exist('tileSizeMM','var')
    tileSizeMM = 30;
end
h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(p,[],3)';

[~,fitP] = rigidFit(xyzmes,ptsOpt);
diff = sqrt(sum((xyzmes-fitP).^2));
valid = ~isnan(sum(xyzmes));
% Remove outlier points when we are close to the right solution.
if sum(diff<tileSizeMM/2)>=(w*h-h)
    valid = logical(valid .* (diff<tileSizeMM/2));
end
distMat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
emat=abs(distMat(xyzmes(:,valid))-distMat(ptsOpt(:,valid)));
e = mean(emat(:));
ptsOut=[];
[e_dist,fitP] = rigidFit(xyzmes(:,valid),ptsOpt(:,valid));

if(exist('verbose','var') && verbose)
%     subplot(131);
%     imagesc(emat);
%     axis square
%     colorbar;
%     subplot(132);
%     histogram(emat(:));
%     axis square
    %     quiver3(ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),xyzmes(1,in)-ptsOptR(1,in),xyzmes(2,in)-ptsOptR(2,in),xyzmes(3,in)-ptsOptR(3,in),0)
    %     plotPlane(mdl);
%     subplot(133);
    figure(190789)
    tabplot;
    plot3(xyzmes(1,valid),xyzmes(2,valid),xyzmes(3,valid),'ro',fitP(1,:),fitP(2,:),fitP(3,:),'g.',xyzmes(1,logical(1-valid)),xyzmes(2,logical(1-valid)),xyzmes(3,logical(1-valid)),'bo');
    titlestr = sprintf('Checkerboard Points in 3D.\n eGeom = %.2f. Invalid#=%d',e,sum(1-valid));
    xlabel('x'),ylabel('y'),zlabel('z'),title(titlestr)
    if sum(1-valid)> 1
        legend({'Measurements' 'Reference','Invalids'})
    else
        legend({'Measurements' 'Reference'})
    end
    drawnow;
    axis equal
end

return
%find best plane
% [mdl,d,in]=planeFit(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:));
% %     if(nnz(in)/numel(in)<.90)
% %         e=1e3;
% %         ptsOut=xyzmes;
% %         return;
% %     end
% c=mean(xyzmes(:,in),2);
% pvc=xyzmes-c;
% 
% %shift to center, find rotation along PCA
% [u,~,vt]=svd(pvc(:,in)*ptsOpt(:,in)');
% rotmat=u*vt';
% 
% ptsOptR = rotmat*ptsOpt;
% 
% errVec = vec(sqrt((sum((pvc-ptsOptR).^2))));
% if(exist('verbose','var') && verbose)
%     
%     plot3(pvc(1,in)+c(1),pvc(2,in)+c(2),pvc(3,in)+c(3),'go',pvc(1,~in)+c(1),pvc(2,~in)+c(2),pvc(3,~in)+c(3),'Ro',ptsOptR(1,in)+c(1),ptsOptR(2,in)+c(2),ptsOptR(3,in)+c(3),'b+')
%     %     quiver3(ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),xyzmes(1,in)-ptsOptR(1,in),xyzmes(2,in)-ptsOptR(2,in),xyzmes(3,in)-ptsOptR(3,in),0)
%     %     plotPlane(mdl);
%     %     plot3(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),'ro',ptsOptR(1,:),ptsOptR(2,:),ptsOptR(3,:),'g.');
%     L=250;
%     set(gca,'xlim',[-L L]+c(1));
%     set(gca,'ylim',[-L L]+c(2));
%     set(gca,'zlim',[-L L]+c(3));
%     xlabel('x');
%     ylabel('y');
%     zlabel('z');
%     axis square
%     grid on
% end
% 
% e = sqrt((mean(errVec(in).^2)));
% %  e=prctile(errVec,85);
% ptsOut = reshape(ptsOptR'+mean(xyzmes(:,in),2)',size(p,1),size(p,2),3);
end
function [e_dist,fitP] = rigidFit(p1,p2)
% finds optimal rot and translation. Returns the error.
c = mean(p1,2);
p1=p1-mean(p1,2);
p2=p2-mean(p2,2);

%shift to center, find rotation along PCA
[u,~,vt]=svd(p1*p2');
rotmat=u*vt';
e_dist = mean(vec(sqrt((sum((p1-rotmat*p2).^2)))));
fitP = rotmat*p2+c; 
end