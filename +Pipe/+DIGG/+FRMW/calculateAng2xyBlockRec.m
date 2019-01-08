function [outRegs] = calculateAng2xyBlockRec(regs)
shift = double(regs.DIGG.bitshift);
toint32 = @(x) int32(x*2^shift);
N = 32;%LUT size

if(regs.DIGG.undistBypass)
    fx = (N-1)/double(regs.FRMW.undistCalImgHsize-1);
    fy = (N-1)/double(regs.FRMW.undistCalImgVsize-1);
    x0=int32(0);
    y0=int32(0);
    x1=int32(regs.FRMW.undistCalImgHsize-1);
    y1=int32(regs.FRMW.undistCalImgVsize-1);
    
else
    a=2047; pixelMarginp=0.0025; % to make sure any x,y is inside thr rectangle
    pixelMarginx=pixelMarginp*double(regs.FRMW.undistCalImgHsize); 
    pixelMarginy=pixelMarginp*double(regs.FRMW.undistCalImgVsize); 

    [angx,angy] = meshgrid(linspace(-a,a,100));
    [x,y] = Calibration.aux.ang2xySF(angx,angy,regs,[],0);
    % block rectangle
    x0 = min(x(:))-pixelMarginx;
    x1 = max(x(:))+pixelMarginx;
    y0 = min(y(:))-pixelMarginy;
    y1 = max(y(:))+pixelMarginy;
    
    
    distortionH=y1-y0;
    distortionW=x1-x0;
    fx = (N-1)/distortionW;
    fy = (N-1)/distortionH;
end

outRegs.DIGG.undistFx = uint32(toint32(fx));
outRegs.DIGG.undistFy = uint32(toint32(fy));
outRegs.DIGG.undistX0 = toint32(x0);
outRegs.DIGG.undistY0 = toint32(y0);



end

