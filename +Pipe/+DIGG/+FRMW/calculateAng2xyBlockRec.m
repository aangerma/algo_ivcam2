function [outRegs] = calculateAng2xyBlockRec(regs)
shift = double(regs.DIGG.bitshift);
toint32 = @(x) int32(x*2^shift);
N = 32;%LUT size

if(regs.DIGG.undistBypass)
    fx = (N-1)/double(regs.FRMW.calImgHsize-1);
    fy = (N-1)/double(regs.FRMW.calImgVsize-1);
    x0=int32(0);
    y0=int32(0);
    x1=int32(regs.FRMW.calImgHsize-1);
    y1=int32(regs.FRMW.calImgVsize-1);
    
else
    a=2047; 
    [angx,angy] = meshgrid(linspace(-a,a,100));

    [x,y] = Calibration.aux.ang2xySF(angx,angy,regs,[],0);

    x1 = min(x(:));
    x30 = max(x(:));
    y1 = min(y(:));
    y30 = max(y(:));
    
    dx = (x30-x1)/(N-3);
    x0 = x1 - dx;
    dy = (y30-y1)/(N-3);
    y0 = y1 - dy;

    fx = 1/dx;
    fy = 1/dy;
end

outRegs.DIGG.undistFx = uint32(toint32(fx));
outRegs.DIGG.undistFy = uint32(toint32(fy));
outRegs.DIGG.undistX0 = toint32(x0);
outRegs.DIGG.undistY0 = toint32(y0);



end

