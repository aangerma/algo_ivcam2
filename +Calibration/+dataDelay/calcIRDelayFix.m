function [d,im,pixVar] = calcIRDelayFix(hw,cbPtsSz)
    %im1 - top to bottom
    %im2 - bottom to top
    
    %init outputs
    d = nan;
    pixVar = nan;
    
    [imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);
    im=cat(3,imD,(imD+imU)/2,imU);

    %time per pixel in spherical coordinates
    nomMirroFreq = 20e3;
    t=@(px)acos(-(px/size(imD,1)*2-1))/(2*pi*nomMirroFreq);
    
    rotateBy180 = 1;
    p1 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imD, rotateBy180);
    p2 = Calibration.aux.CBTools.findCheckerboardFullMatrix(imU, rotateBy180);
    if ~isempty(p1(~isnan(p1))) && ~isempty(p2(~isnan(p2)))
       
        d=round(nanmean(vec(t(p1(:,:,2))-t(p2(:,:,2))))/2*1e9);
        diff = p1(:,:,2)-p2(:,:,2);
        diff = diff(~isnan(diff));
        pixVar = var(diff);
    end
    
end


