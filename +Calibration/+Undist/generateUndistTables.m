function [udistLUT,xg,yg,undistx,undisty]=generateUndistTables(s,d,wh,pmargin)
N=32;
wh=fliplr(wh);

x0 = -ceil(wh(1)*pmargin);
x1 =  ceil(wh(1)*(1+pmargin));
y0 = -ceil(wh(2)*pmargin);
y1 =  ceil(wh(2)*(1+pmargin));
distortionH=y1-y0;
distortionW=x1-x0;
fx = (N-1)/distortionW;
fy = (N-1)/distortionH;
[yg,xg]=ndgrid(1/fy*(0:31)+y0,1/fx*(0:31)+x0);

%  bdpts=interp1(0:4,[0 0;1 0;1 1;0 1;0 0],(0:0.1:3.9))'.*[distortionW;distortionH]+[x0;y0];
%  s=[s bdpts];d=[d bdpts];
 tps=TPS(s',d'-s');
 undist=tps.at([xg(:) yg(:)]);
%  undist=[vec(griddata(s(1,:),s(2,:),d(1,:)-s(1,:),xg,yg,'cubic')) vec(griddata(s(1,:),s(2,:),d(2,:)-s(2,:),xg,yg, 'cubic')  )];
undist(isnan(undist))=0;
undistx=reshape(undist(:,1),size(xg));
undisty=reshape(undist(:,2),size(yg));
% undistx = removeXscaling(undistx);
% undisty= removeXscaling(undisty')';
[yg,xg]=ndgrid(linspace(-1,1,32));

udistLUT = typecast(vec(single([undistx(:) undisty(:)]')./wh'),'uint32');


% quiver(s(1,:),s(2,:),d(1,:)-s(1,:),d(2,:)-s(2,:))
% rectangle('position',[1 1 wh])
% hold on
% quiver(xg,yg,undistx,undisty)
% hold off

end


function m=removeXscaling(matin)
[~,xg]=ndgrid(linspace(-1,1,32));
H=[xg(:) ones(32*32,1)];
th = H\matin(:);
e=abs(H*th-matin(:));
inl=(e<prctile(e,75));
th = H(inl,:)\matin(inl);
m=matin-(xg*th(1)+th(2));
end
