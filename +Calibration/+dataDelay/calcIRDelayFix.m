function [d,im,pixVar] = calcIRDelayFix(hw)
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
    
    p1 = detectCheckerboardPoints(imD);
    p2 = detectCheckerboardPoints(imU);
    if ~isempty(p1) && numel(p1)== numel(p2)  
        d=round(mean(t(p1(:,2))-t(p2(:,2)))/2*1e9);
        pixVar = var((p1(:,2))-(p2(:,2)));
    end
    
end


