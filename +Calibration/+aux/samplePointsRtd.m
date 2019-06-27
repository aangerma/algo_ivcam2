function [rpt] = samplePointsRtd(z,pts,regs,addZ)
    %SAMPLEPOINTSRTD Summary of this function goes here
    %   Detailed explanation goes here
    if ~exist('addZ','var')
        addZ = 0;
    end
    
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
        [angx,angy] = Calibration.aux.vec2ang(Calibration.aux.xy2vec(xg+0.5,yg+0.5,regs), regs);
        [angx,angy] = Calibration.Undist.inversePolyUndistAndPitchFix(angx,angy,regs);
    end
    pts = reshape(pts,[],2);
    it = @(k) interp2(xg,yg,k,pts(:,1)-1,pts(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    if addZ
        rpt=cat(2,it(rtd),it(angx),it(angy),it(single(z))); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    else
        rpt=cat(2,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    end
end

