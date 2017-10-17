function img = displayPipeOutData(po,figTitle)
[h,w]=size(po.zImg);

%     arcball(xImg(:),yImg(:),zImg(:));

% po.zImg = flip(po.zImg,2);
% po.iImg = flip(po.iImg,2);
% po.cImg = flip(po.cImg,2);
% po.vImg = flip(po.vImg,2);

f=figure(354343);
set(f,'name',figTitle,'numberTitle','off');
% clf
N = 4;
profileXlocs = round(size(po.zImg,2).*(1:1:N-1)/N);
profileYlocs = round(size(po.zImg,1).*(1:1:N-1)/N);
%     maximize(gcf);
[pd,planeabcd]=ransacPlane(po.vImg);
pd = pd+planeabcd(end);
pdlims = nanprctile(pd(:),[10 90])+[0 1e-3];
profCols = hsv(max(length(profileXlocs),length(profileYlocs)));

subplot(221);
imagescNAN(po.cImg,[0 15]);
title('Confidence');axis image;colorbar;

subplot(223);
imagescNAN(pd,pdlims);title(sprintf('Rotated z (z=%f)',planeabcd(end)));axis image;colorbar;



if(numel(pd)>10)
    profsX = arrayfun(@(x) pd(:,x),profileXlocs,'uni',false);
    profsY = arrayfun(@(x) pd(x,:)',profileYlocs,'uni',false);
    arrayfun(@(x) line(profileXlocs(x).*[1 1],[1 size(po.zImg,1)],'color',profCols(x,:),'linewidth',2),1:length(profileXlocs));
    arrayfun(@(x) line([1 w],profileYlocs(x).*[1 1],'color',profCols(x,:),'linewidth',2),1:length(profileYlocs));
    
    ax=subplot(422);
    hold(ax,'on');
    arrayfun(@(i) plot(1:h,profsX{i},'color',profCols(i,:)),1:length(profsX));
    hold(ax,'off');
    set(gca,'ylim',pdlims);
    legend(arrayfun(@(i) sprintf('x:%03d \\mu:%1.5g \\sigma:%0.3g',profileXlocs(i),mean(profsX{i}(~isnan(profsX{i}))),std(profsX{i}(~isnan(profsX{i})))),1:length(profsX),'uni',false),'location','best')
    title('Y profile');xlabel('y');ylabel('d from plane');grid minor
    ax=subplot(424);
    hold(ax,'on');
    arrayfun(@(i) plot(1:w,profsY{i},'color',profCols(i,:)),1:length(profsY));
    hold(ax,'off');
    set(gca,'ylim',pdlims);
    legend(arrayfun(@(i) sprintf('x:%03d \\mu:%1.5g \\sigma:%0.3g',profileYlocs(i),mean(profsY{i}(~isnan(profsY{i}))),std(profsY{i}(~isnan(profsY{i})))),1:length(profsY),'uni',false),'location','best')
    title('X profile');xlabel('y');ylabel('d from plane');grid minor
    
end


ax=subplot(224);

if(po.regs.JFIL.bypassIr2Conf)
    irImg = uint16(po.iImg) + bitshift(uint16(po.cImg),8);
    irLims = minmax(irImg)+uint16([0 1]);
else
    irImg = po.iImg;
    irLims = [0 255];
end

imagesc(irImg,irLims);title('IR image');axis image;colorbar;
colormap(ax,gray(256));
%       imagesc(thrImg);title('Confidence image');axis image;colorbar;
if(nargout>0)
    %     p = get(f,'position');
    %     set(f,'position',[1 1 1280 960]);
    drawnow;
    pause(1);
    img = getframe(f);
    img = img.cdata;
    %     set(f,'position',p);
end

end

function v=nanprctile(y,p)
v=double(prctile_(y,p));
if(all(isnan(v)))
    v=interp1([0 100],[0 1],p);
end
end



function [d,bestModel]=ransacPlane(v)
rng(1);
% v = double(v);
x = v(:,:,1);
y = v(:,:,2);
z = v(:,:,3);
bdmsk = z(:)==0 | isnan(z(:));
p=[x(:) y(:) z(:)];
p(bdmsk(:),:)=[];

bestModel=[0 0 0]';
d=nan(size(x));
if(size(p,1)<10)
    return;
end
n = size(p,1);
bestNinlier=0;

thr = 10;
for i=1:1000
    h=p(randperm(n,3),:);
    A = double([h(:,1:2) ones(3,1)]);
    if(abs(det(A))<1e-1)
        continue;
    end
    %fit model z = ax+by+c
    th = pinv(A'*A)*A'*h(:,3);%A\h(:,3);
    e = abs(p(:,1:2)*th(1:2)+th(3)-p(:,3));
    thisNinliers = nnz(e<thr);
    if(bestNinlier<thisNinliers )
        bestNinlier=thisNinliers ;
        bestModel = th;
    end
    
end
if(bestNinlier/n<.1)
    %not planar!
    bestModel = [0 0 0]';
else
    e = abs(p(:,1:2)*bestModel(1:2)+bestModel(3)-p(:,3));
    A = [p(e<thr,1:2) ones(nnz(e<thr),1)];
    if(abs(det(A'*A))<1e-3)
        bestModel = [0 0 0]';
    else
        yy = p(e<thr,3);
        bestModel = pinv(A'*A)*A'*yy;%A\yy;
    end
end
bestModel = [-bestModel(1) -bestModel(2) 1 -bestModel(3)] ;
if(bestModel(4)<0)
    bestModel=-bestModel;
end
normModel = bestModel/norm(bestModel);
%in case the model plane  is almost parallel to the xy axis - make it
%parallel
if(acosd(normModel(3))<1.0)
    bestModel=[0 0 1 bestModel(4)];
end

e = ([x(:) y(:) z(:) ones(numel(z),1)]*bestModel');

d=reshape(e,size(x));
d(bdmsk)=nan;

end
