function [res] = anglesFromPoints(z,pts,regs)
    % from Calibration.aux.SAMPLEPOINTSRTD 
    
    %calc angles per pixel
    [yg,xg]=ndgrid(0:size(z,1)-1,0:size(z,2)-1);
    if(regs.DIGG.sphericalEn)
        xx = (xg+0.5)*4 - double(regs.DIGG.sphericalOffset(1));
        yy = yg + 1 - double(regs.DIGG.sphericalOffset(2));
        
        xx = xx*2^10;
        yy = yy*2^12;
        
        angx = xx/double(regs.DIGG.sphericalScale(1));
        angy = yy/double(regs.DIGG.sphericalScale(2));
    else
        error 'Spherical only';
    end
    pts = reshape(pts,[],2);
    it = @(k) interp2(xg,yg,k,pts(:,1)-1,pts(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    res=cat(2,it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
end

