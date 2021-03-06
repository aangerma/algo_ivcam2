function [e,e_dist,ptsOut]=evalGeometricDistortion(p,pts3d,runParams)
%%
%{
if ~exist('tileSizeMM','var')
    tileSizeMM = 30;
end
h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
pts3d = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(p,[],3)';
%}
 %get the tile size from the 3d points
if ~exist('runParams','var')
    runParams = [];
end
tileSize = min(sqrt(sum(diff(pts3d).^2,2)));

%perform rigid fit and find distance from optimal grid
validRaw = ~isnan(sum(p,2));
pValidRaw = p(validRaw,:);
pts3dValidRaw = pts3d(validRaw,:);
[err,fitP] = Calibration.aux.rigidFit(pValidRaw,pts3dValidRaw);
fitErr = sqrt(sum((pValidRaw-fitP).^2,2));

% Remove outlier points when we are close to the right solution.
valid = validRaw;
if sum(fitErr<tileSize/2) >= 0.92*size(pts3dValidRaw,1)
    valid(validRaw) = logical(valid(validRaw) .* (fitErr<tileSize/2));
end
distVec = @(m) pdist(m);
emat=abs(distVec(p(valid,:))-distVec(pts3d(valid,:)));
e = sum(emat(:))*2./(sum(valid))^2; % division by (N^2)/2 instead of N*(N-1)/2 - due to legacy 

ptsOut=[];
[e_dist,fitP] = Calibration.aux.rigidFit(p(valid,:),pts3d(valid,:));

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
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

%     currfig = figure(190789);
    currfig = Calibration.aux.invisibleFigure;
    tabplot;
    plot3(p(valid,1),p(valid,2),p(valid,3),'ro',fitP(:,1),fitP(:,2),fitP(:,3),'g.',p(~valid,1),p(~valid,2),p(~valid,3),'bo');
    titlestr = sprintf('Checkerboard Points in 3D.\n eGeom = %.2f. Invalid#=%d',e,sum(1-valid));
    xlabel('x'),ylabel('y'),zlabel('z'),title(titlestr)
    if sum(1-valid)> 1
        legend({'Measurements' 'Reference','Invalids'})
    else
        legend({'Measurements' 'Reference'})
    end
    drawnow;
    axis equal
    if currfig.isvalid
        Calibration.aux.saveFigureAsImage(currfig,runParams,'DFZ','3D',1,1);
    end
    % openfig("C:\temp\unitCalib\F9090111\PC04\F9090111\PC01\figures\DFZ_3D_00.fig",'new','visible')
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