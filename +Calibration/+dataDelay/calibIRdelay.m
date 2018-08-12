function [delayIR,ok, pixelVar] = calibIRdelay(hw,dataDelayParams,verbose)
    
    delayIR = dataDelayParams.slowDelayInitVal;

    ok=false;
    pixelVar = NaN;
    
    d=nan(dataDelayParams.nAttempts,1);
    for i=1:dataDelayParams.nAttempts
        Calibration.dataDelay.setAbsDelay(hw,[],delayIR);
        [d(i),im, pixelVar]=Calibration.dataDelay.calcIRDelayFix(hw);
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

