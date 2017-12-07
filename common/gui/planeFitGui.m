function validRMSE = planeFitGui(varargin)

if(nargin==0)
    h = gcf;
    I = getimage(h);
elseif(nargin==1)
   if( strcmp(get(varargin{1},'type'),'figure') || strcmp(get(varargin{1},'type'),'axes') )
       h = varargin{1};
       I = getimage(varargin{1});
   else
       error('unsoppurted input- should be figure or axes handle');
   end
else
    error('number of input vars should be 0/1');
end
       
rect = round(getrect(h));
xEdge = rect(1):rect(1)+rect(3);
yEdge = rect(2):rect(2)+rect(4);
[x ,y]= meshgrid(xEdge,yEdge);
z = reshape(I(sub2ind(size(I),y(:),x(:))),size(x));

nanMask = isnan(z);
%  figure;imagesc(z)

[normal,distFromPlane, validInd] = planeFit(x(~nanMask),y(~nanMask),double(z(~nanMask)));

zPlane = (normal(1)*x+normal(2)*y+normal(4))/-normal(3);

figure;
surf(x,y,z,'LineStyle',':');hold on; surf(x,y,zPlane,'LineStyle',':','FaceColor','r')
set(gca,'zdir','reverse')


validRMSE =  sqrt(sum(vec(distFromPlane(validInd)).^2)/sum(validInd));
title(['valid RMSE: ' num2str(validRMSE)]);
end
