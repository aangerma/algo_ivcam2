function [udistLUT,undistx,undisty]=generateUndistTablesFromGridPointsOnly(regs)

wh=double([regs.GNRL.imgHsize,regs.GNRL.imgVsize]);
shift = double(regs.DIGG.bitshift);

x0 = single(regs.DIGG.undistX0)/(2^shift);
y0 = single(regs.DIGG.undistY0)/(2^shift);
fx = single(regs.DIGG.undistFx)/(2^shift);
fy = single(regs.DIGG.undistFy)/(2^shift);
[ybug,xbug]=ndgrid(1/fy*(0:31)+y0,1/fx*(0:31)+x0);

% transform grid of bugged XY to angles as would be reported by MC
[angxg,angyg] = Calibration.aux.xy2angSF(xbug(:),ybug(:),regs);
% transform angles as reported by MC to final XY (using correct transformations)
[angxPostPolyUndist,angyPostPolyUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(angxg,angyg,regs);
v = Calibration.aux.ang2vec(angxPostPolyUndist,angyPostPolyUndist,regs);
[xg,yg] = Calibration.aux.vec2xy(v,regs);

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


