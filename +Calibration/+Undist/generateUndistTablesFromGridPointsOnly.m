function [udistLUT,undistx,undisty]=generateUndistTablesFromGridPointsOnly(regs)

wh=double([regs.GNRL.imgHsize,regs.GNRL.imgVsize]);
shift = double(regs.DIGG.bitshift);

x0 = single(regs.DIGG.undistX0)/(2^shift);
y0 = single(regs.DIGG.undistY0)/(2^shift);
fx = single(regs.DIGG.undistFx)/(2^shift);
fy = single(regs.DIGG.undistFy)/(2^shift);
[ybug,xbug]=ndgrid(1/fy*(0:31)+y0,1/fx*(0:31)+x0);


[angxg,angyg] = Calibration.aux.xy2angSF(xbug(:),ybug(:),regs,false);
angxPostPolyUndist = Calibration.Undist.applyPolyUndist(angxg,regs);
% Transform the angx-angy into x-y. Using the bugged ang2xy:
[xg,yg] = Calibration.aux.ang2xySF(angxPostPolyUndist,angyg,regs,[],true);
undist = [xg-xbug(:),yg-ybug(:)];

undistx=reshape(undist(:,1),size(xbug));
undisty=reshape(undist(:,2),size(ybug));
% undistx = removeXscaling(undistx);
% undisty= removeXscaling(undisty')';

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
