function [delayIR,ok, pixelVar] = calibIRdelay(hw,dataDelayParams,verbose)
    
    delayIR = dataDelayParams.slowDelayInitVal;

    ok=false;
    pixelVar = NaN;
    
    d=nan(dataDelayParams.nAttempts,1);
    for i=1:dataDelayParams.nAttempts
        Calibration.dataDelay.setAbsDelay(hw,[],delayIR);
        [d(i),im, pixelVar]=calcDelayFix(hw);
        if (isnan(d(i)))%CB was not found, throw delay forward to find a good location
            d(i) = 3000;
        end
        if (verbose)
            figure(sum(mfilename));
            imagesc(im);
            title(sprintf('IR delay: %d (%d)',delayIR,d(i)));
            drawnow;
        end
        
        if (abs(d(i))<=dataDelayParams.iterFixThr)
            ok=true;
            break;
        end
        
        nsEps = 2;
        if (i>1 && abs(d(i))-nsEps > abs(d(i-1)))
            warning('delay not converging!');
            break;
        end
        
        delayIR=delayIR+d(i);
        if (delayIR<0)
            break;
        end
    end
    
    if (verbose)
        close(sum(mfilename));
        drawnow;
    end
end

function [d,im,pixVar]=calcDelayFix(hw)
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
