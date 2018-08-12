function [d,im]=calcIRDelayFix(hw)
    %im1 - top to bottom
    %im2 - bottom to top
    [imU,imD]=Calibration.dataDelay.getScanDirImgs(hw);
    
    %time per pixel in spherical coordinates
    nomMirroFreq = 20e3;
    t=@(px)acos(-(px/size(imD,1)*2-1))/(2*pi*nomMirroFreq);
    
    p1 = detectCheckerboardPoints(imD);
    p2 = detectCheckerboardPoints(imU);
    if(isempty(p1) || numel(p1)~=numel(p2))
        d=nan;
    else
        d=round(mean(t(p1(:,2))-t(p2(:,2)))/2*1e9);
    end
    
    im=cat(3,imD,(imD+imU)/2,imU);
    
end


