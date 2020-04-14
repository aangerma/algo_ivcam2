function out = DsmToSphericalPixel(in, regs, mode)
    % DsmToSphericalPixel
    %   Converts DSM angles to pixels in spherical mode, and vice versa.
    
    if strcmp(mode, 'direct') % DSM to spherical pixel
        xx = in.angx*double(regs.DIGG.sphericalScale(1));
        yy = in.angy*double(regs.DIGG.sphericalScale(2));
        xx = xx/(2^10);
        yy = yy/(2^12);
        out.x = (xx + double(regs.DIGG.sphericalOffset(1)))/4 - 0.5;
        out.y = (yy + double(regs.DIGG.sphericalOffset(2))) - 1;
        
    elseif strcmp(mode, 'inverse') % spherical pixel to DSM
        xx = (in.x+0.5)*4 - double(regs.DIGG.sphericalOffset(1));
        yy = in.y + 1 - double(regs.DIGG.sphericalOffset(2));
        xx = xx*(2^10);
        yy = yy*(2^12);
        out.angx = xx/double(regs.DIGG.sphericalScale(1));
        out.angy = yy/double(regs.DIGG.sphericalScale(2));
        
    else
        error('Illegal mode: mode can be either ''direct'' or ''inverse''.')
        
    end
    
end
