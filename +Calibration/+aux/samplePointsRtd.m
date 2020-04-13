function [rpt,pts,colorMap] = samplePointsRtd(z,pts,regs,addZ,colorMap,takeRtdValuesFromWhite)
    %SAMPLEPOINTSRTD Summary of this function goes here
    %   Detailed explanation goes here
    advancedMode = (nargin>4);
    if advancedMode
        sz = size(colorMap);
    end
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
        dsmAngles = Utils.convert.DsmToSphericalPixel(struct('x', xg, 'y', yg), regs, 'backward');
        angx = dsmAngles.angx;
        angy = dsmAngles.angy;
    else
        [angx,angy] = Calibration.aux.vec2ang(Calibration.aux.xy2vec(xg+0.5,yg+0.5,regs), regs);
        [angx,angy] = Calibration.Undist.inversePolyUndistAndPitchFix(angx,angy,regs);
    end
    ptsCols = reshape(pts,[],2);
    it = @(k) interp2(xg,yg,k,ptsCols(:,1)-1,ptsCols(:,2)-1); % Used to get depth and ir values at checkerboard locations.
    %rtd,phi,theta
    if addZ
        rpt=cat(2,it(rtd),it(angx),it(angy),it(single(z))); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    else
        rpt=cat(2,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    end
    
    if advancedMode
        if takeRtdValuesFromWhite
            [rtdSampledFromWhite,ptsFromWhite1,ptsFromWhite2,pts,colorMap] = CBTools.valuesFromWhitesNonSq(rtd,pts,colorMap,1/8);
            % rtdFromWhite = nan(size(pts,1)*size(pts,2),1);
            % %rtdFromWhite(reshape(~isnan(pts(:,:,1)),size(rtdFromWhite))) = rtdSampledFromWhite;
            % rtdFromWhite(reshape(any(~isnan(pts(:,:,1)),1) & any(~isnan(pts(:,:,1)),2),size(rtdFromWhite))) = rtdSampledFromWhite;
            rpt(:,1) = rtdSampledFromWhite;
        end
    end
end

