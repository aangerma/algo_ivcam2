function [uv_erros, sampleDist] = calcUvMapError(lutCheckers,hfactor,vfactor,cal)
    %CALCUVMAPERROR Summary of this function goes here
    %   Detailed explanation goes here
    [sampleDist,idx] = min(sqrt(([lutCheckers(:).hScale]-hfactor).^2 + ([lutCheckers.vScale]-vfactor).^2));
    
    %ptsI = lutCheckers(idx).irPts;
    pointCloud = lutCheckers(idx).zPts;
    ptsRgb = lutCheckers(idx).rgbPts;
    
    
    rgbKn = du.math.normalizeK(cal.Krgb, cal.rgbRes);
    Pt = rgbKn*[cal.Rrgb cal.Trgb];
    [U, V] = du.math.mapTexture(Pt,pointCloud(1,:)',pointCloud(2,:)',pointCloud(3,:)');
    uvmap = [cal.rgbRes(1).*U';cal.rgbRes(2).*V'];
    uvmap_d = du.math.distortCam(uvmap, cal.Krgb, cal.rgbDistort);
    errs = reshape(ptsRgb,[],2) - uvmap_d';
    
    uv_erros = [sqrt(nanmean(sum(errs.^2,2)))  prctile(sqrt(sum(errs.^2,2)),95) prctile(errs,50)] ;
end

