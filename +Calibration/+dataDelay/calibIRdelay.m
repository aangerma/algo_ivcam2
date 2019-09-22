function [delayIR,ok, pixelVar] = calibIRdelay(hw, dataDelayParams, runParams, calibParams, isFinalStage)
    verbose = 1;
    delayIR = dataDelayParams.slowDelayInitVal;

    ok=false;
    pixelVar = NaN;
    
    
    
    d=nan(dataDelayParams.nAttempts,1);
    for i=1:dataDelayParams.nAttempts
 %       Calibration.dataDelay.setAbsDelay(hw,[],delayIR);
        
       if (i==1)
           % Save initial up down frames
           if isFinalStage
               figureFileName = 'FinalStage_Initial';
           else
               figureFileName = 'InitStage_Initial';
           end
           Calibration.dataDelay.saveCurrentUpDown(hw,runParams,'IR_Delay',figureFileName,sprintf('Up/Down Images - Initial (%d)',delayIR)); 
        end
        
        [res, d(i),im,pixelVar] = Calibration.dataDelay.IR_DelayCalib(hw, delayIR, calibParams, false, isFinalStage);  
        if (verbose)
            figure(sum(mfilename));
            imagesc(im);
            title(sprintf('IR delay: %d (%d)',delayIR,d(i)-delayIR));
            drawnow;
        end
        delayIR = d(i);
        
        if (res==1)
            ok=true;
            break;
        end
        if (res==-1)
            warning('delay not converging!');
            break;
        end
    end
    
    if (verbose)
        close(sum(mfilename));
        drawnow;
    end
    % Save initial up down frames
    Calibration.dataDelay.saveCurrentUpDown(hw,runParams,'IR_Delay','Final',sprintf('Up/Down Images - Final(%d)',delayIR));
    
end
