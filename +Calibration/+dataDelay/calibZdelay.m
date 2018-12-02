function [delayZ,ok] = calibZdelay(hw,dataDelayParams,runParams)
verbose = runParams.verbose;
delayZ=dataDelayParams.slowDelayInitVal+dataDelayParams.fastDelatInitOffset;


imB=double(hw.getFrame(30).i)/255;


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
       Calibration.dataDelay.saveCurrentUpDown(hw,runParams,'Z_Delay','Initial',sprintf('Up/Down Images - Initial (%d)',delayZ)); 
    end
    [d(i),im]=Calibration.dataDelay.calcZDelayFix(hw,imB);
    if (isnan(d(i)))%CB was not found, throw delay forward to find a good location
        d(i) = 3000;
    end
    if (verbose)
        figure(sum(mfilename));
        imagesc(im);
        title(sprintf('Z delay: %d (%d)',delayZ,d(i)));
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
    
    delayZ=delayZ+d(i);
    
    if (delayZ<0)
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




