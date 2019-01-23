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
        yy = double(yg);
        xx = double((xg)*4);
        xx = xx-double(regs.DIGG.sphericalOffset(1));
        yy = yy-double(regs.DIGG.sphericalOffset(2));
        xx = xx*2^10;%bitshift(xx,+12-2);
        yy = yy*2^12;%bitshift(yy,+12);
        xx = xx/double(regs.DIGG.sphericalScale(1));
        yy = yy/double(regs.DIGG.sphericalScale(2));
        
        angx = single(xx);
        angy = single(yy);
    else
        [angx,angy]=Calibration.aux.xy2angSF(xg,yg,regs,0);
    end
    
    %find CB points
    %{
            warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
            [p,bsz] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(darr(i).i)), calibParams.gnrl.cbPtsSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
            
            if isempty(p)
                fprintff('Error: checkerboard not detected!');
            end
        
            it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz),reshape(p(:,2)-1,bsz)); % Used to get depth and ir values at checkerboard locations.
    %}
    it = @(k) interp2(xg,yg,k,pts(:,1)-1,pts(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    rpt=cat(2,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
end

