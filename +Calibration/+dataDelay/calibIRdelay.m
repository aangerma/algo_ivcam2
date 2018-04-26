function [delayIR,ok] = calibIRdelay(hw,dataDelayParams,verbose)
    
    delayIR=dataDelayParams.slowDelayInitVal;
    
    
    ok=false;
    
    d=nan(dataDelayParams.nAttempts,1);
    for i=1:dataDelayParams.nAttempts
        Calibration.dataDelay.setAbsDelay(hw,[],delayIR);
        [d(i),im]=calcDelayFix(hw);
        if(isnan(d(i)))%CB was not found, throw delay forward to find a good location
            d(i) = 3000;
        end
        if(verbose)
            figure(sum(mfilename));
            imagesc(im);
            title(sprintf('%d (%d)',delayIR,d(i)));
            drawnow;
        end
        
        if(d(i)<=dataDelayParams.iterFixThr)
            ok=true;
            break;
        end
        if(i==2 && abs(d(2))>abs(d(1)))
            warning('delay not converging!');
            break;
        end
        delayIR=delayIR+d(i);
        if(delayIR<0)
            break;
        end
    end
    if(verbose)
        close(sum(mfilename));
        drawnow;
    end
end

function [d,im]=calcDelayFix(hw)
    %im1 - top to bottom
    %im2 - bottom to top
    [im2,im1]=Calibration.dataDelay.getScanDirImgs(hw);
    
    %time per pixel in spherical coordinates
    nomMirroFreq = 20e3;
    t=@(px)acos(-(px/size(im1,1)*2-1))/(2*pi*nomMirroFreq);
    
    p1 = detectCheckerboardPoints(im1);
    p2 = detectCheckerboardPoints(im2);
    if(isempty(p1) || numel(p1)~=numel(p2))
        d=nan;
    else
        d=round(mean(t(p1(:,2))-t(p2(:,2)))/2*1e9);
    end
    
    im=cat(3,im1,(im1+im2)/2,im2);
    
end
