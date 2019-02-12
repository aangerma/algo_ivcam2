function [rpt] = samplePointsRtd(z,pts,regs)
    %SAMPLEPOINTSRTD Summary of this function goes here
    %   Detailed explanation goes here
    if ~regs.DEST.depthAsRange
        [~,r] = Pipe.z16toVerts(z,regs);
    else
        r = double(z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
    end
    % get rtd from r
    [~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
    
    C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
    rtd=r+sqrt(r.^2-C);
    rtd=rtd+regs.DEST.txFRQpd(1);
    
    %calc angles per pixel
    [yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
    if(regs.DIGG.sphericalEn)
        xx = (xg+0.5)*4 - double(regs.DIGG.sphericalOffset(1));
        yy = yg + 1 - double(regs.DIGG.sphericalOffset(2));
        
        xx = xx*2^10;
        yy = yy*2^12;
        
        angx = xx/double(regs.DIGG.sphericalScale(1));
        angy = yy/double(regs.DIGG.sphericalScale(2));
    else
        [angx,angy]=Calibration.aux.xy2angSF(xg+0.5,yg+0.5,regs,1);
        angx = Calibration.Undist.inversePolyUndist(angx,regs);
    end
    pts = reshape(pts,[],2);
    it = @(k) interp2(xg,yg,k,pts(:,1)-1,pts(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    rpt=cat(2,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
end

