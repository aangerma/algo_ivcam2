function [udistLUT,undistx,undisty]=generateUndistTablesFromGridPointsOnly(regs,origRegs,FE)

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


if ~isempty(FE)
%     v = Calibration.aux.xy2vec(xg,yg,regs); % for each pixel, get the unit vector in space corresponding to it.
%     [angxg,angyg] = Calibration.aux.vec2ang(v,origregs,FE);
    
    v = Calibration.aux.ang2vec(angxPostPolyUndist,angyg,origRegs,FE);
    [xg,yg] = Calibration.aux.vec2xy(v,regs);
else
    [xg,yg] = Calibration.aux.ang2xySF(angxPostPolyUndist,angyg,origRegs,[],true);
end


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


