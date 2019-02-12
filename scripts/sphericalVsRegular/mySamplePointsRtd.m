function [rpt,cbr,cbsing,verts] = mySamplePointsRtd(z,pts,regs)
    %SAMPLEPOINTSRTD Summary of this function goes here
    %   Detailed explanation goes here
    if ~regs.DEST.depthAsRange
        [verts,r] = Pipe.z16toVerts(z,regs);
    else
        verts = [];
        r = double(z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
    end
%     [yg,xg]=ndgrid(0:size(r,1)-1,0:size(r,2)-1);
%     tanx = xg*regs.DEST.p2axa+regs.DEST.p2axb;
%     tany = yg*regs.DEST.p2aya+regs.DEST.p2ayb;
%     sing = tany./sqrt(tanx.^2+tany.^2+1);
    % get rtd from r
    [~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
    
    C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
    rtd=r+sqrt(r.^2-C);
    rtd=rtd+regs.DEST.txFRQpd(1);
    
    %calc angles per pixel
    [yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
    if(regs.DIGG.sphericalEn)
        xx = (xg+0.5)*4 - double(regs.DIGG.sphericalOffset(1));
        yy = yg+0.5 - double(regs.DIGG.sphericalOffset(2));
        
        xx = xx*2^10;
        yy = yy*2^12;
        
        angx = xx/double(regs.DIGG.sphericalScale(1));
        angy = yy/double(regs.DIGG.sphericalScale(2));
        
        
%         xx = int32(angxQ);
%     yy = int32(angyQ);
%     
%     xx = xx*int32(regs.DIGG.sphericalScale(1));
%     yy = yy*int32(regs.DIGG.sphericalScale(2));
%     
%     xx = bitshift(xx,-12+2);
%     yy = bitshift(yy,-12);
%     
%     xx = xx+int32(regs.DIGG.sphericalOffset(1));
%     yy = yy+int32(regs.DIGG.sphericalOffset(2));
%     
%     xx = max(-2^14,min(2^14-1,xx));%15bit signed data
%     yy = max(-2^11,min(2^11-1,yy));%12bit signed data
    
%         [angy,angx] = ndgrid(linspace(-2047,2047,size(rtd,1)),linspace(-2047,2047,size(rtd,2)));
    else
        [angx,angy]=Calibration.aux.xy2angSF(xg+0.5,yg+0.5,regs,1);
        angx = Calibration.Undist.inversePolyUndist(angx,regs);
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
%     pts(isnan(pts(:,1)),:) = []; 
    pts = reshape(pts,[],2);
    it = @(k) interp2(xg,yg,k,pts(:,1)-1,pts(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    rpt=cat(2,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    cbr = it(r);
    cbsing = it(sing);
end

