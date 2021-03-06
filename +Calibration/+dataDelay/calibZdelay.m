function [delayZ,ok] = calibZdelay(hw, dataDelayParams, runParams, calibParams, isFinalStage, fResMirror)
verbose = 1;
NumberOfFrames = calibParams.gnrl.Nof2avg;
delayZ=dataDelayParams.fastDelayInitVal;
% delayZ=dataDelayParams.slowDelayInitVal+dataDelayParams.fastDelatInitOffset;

frameBytesBoth = Calibration.aux.captureFramesWrapper(hw, 'I', NumberOfFrames);

[~,saveVal] = hw.cmd('irb e2 06 01'); % Original Laser Bias
hw.cmd('iwb e2 06 01 00'); % set Laser Bias to 0
hw.setReg('DESTaltIrEn', true);

ok=false;

d=nan(dataDelayParams.nAttempts,1);
for i=1:dataDelayParams.nAttempts
    Calibration.dataDelay.setAbsDelay(hw,delayZ,[]);
    pause(0.1);
    if i==1
       % Save initial up down frames
       if isFinalStage
           figureFileName = 'FinalStage_Initial';
       else
           figureFileName = 'InitStage_Initial';
       end
       Calibration.dataDelay.saveCurrentUpDown(hw,runParams,'Z_Delay',figureFileName,sprintf('Up/Down Images - Initial (%d)',delayZ)); 
    end
        [res, d(i),im] = Calibration.dataDelay.Z_DelayCalib(hw, frameBytesBoth, delayZ, runParams, calibParams, isFinalStage, fResMirror); 
		
       if (verbose)
            figure(sum(mfilename));
            imagesc(im);
            title(sprintf('Z delay: %d (%d)',delayZ,d(i)-delayZ));
            drawnow;
        end
        delayZ = d(i);
        if (res==1)
            ok=true;
            break;    
        end
        if (res==-1)
            warning('delay not converging!');
            break;
        end
end

hw.setReg('DESTaltIrEn', false);
hw.cmd(sprintf('iwb e2 06 01 %02x',saveVal)); %reset value
% Save final up down frames
Calibration.dataDelay.saveCurrentUpDown(hw,runParams,'Z_Delay','Final',sprintf('Up/Down Images - Final (%d)',delayZ)); 
if(verbose)
    close(sum(mfilename));
    drawnow;
end
end




