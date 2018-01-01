function [undistx,undisty]=generateUndistTables(im,regs)

[e,s,d]=Calibration.aux.evalProjectiveDisotrtion(im);
bdpts=(interp1(0:4,[0 0;1 0;1 1;0 1;0 0],0:0.1:4)).*fliplr(size(im));
s=[s;bdpts];d=[d;bdpts];
tps=TPS(s,d-s);
tod = @(v) double(v)/2^double(regs.DIGG.bitshift);
[yg,xg]=ndgrid(1/tod(regs.DIGG.undistFy)*(0:31)+tod(regs.DIGG.undistY0),...
    1/tod(regs.DIGG.undistFx)*(0:31)+tod(regs.DIGG.undistX0));
undist=tps.at([xg(:) yg(:)]);
undistx=reshape(undist(:,1),size(xg));
undisty=reshape(undist(:,2),size(yg));
end