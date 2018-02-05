function [imgBefore,imgAfter] = setNewSlowDelay(hw, delay)

hw.runCommand('mwd a00e1b24 a00e1b28 00000001 //JFILsort1bypassMode');
hw.runCommand('mwd a00e084c a00e0850 00000000 //DESTaltIrEn');
hw.shadowUpdate();

frame = hw.getFrame();
imgBefore = double(frame.i);

hw.stopStream();
pause(0.1);     
    
slowDelayCmd = 'mwd a0060008 a006000c 8%07x // RegsAnsyncAsLateLatencyFixEn';

hw.runCommand(sprintf(slowDelayCmd, delay));
    
hw.shadowUpdate();
    
hw.restartStream();
pause(0.2);
    
frame = hw.getFrame();
imgAfter = double(frame.i);

figure(21712);
ax1 = subplot(1,2,1); imagesc(imgBefore, prctile_(imgBefore(imgBefore~=0),[10 90])+[0 1e-3]);
ax2 = subplot(1,2,2); imagesc(imgAfter, prctile_(imgAfter(imgAfter~=0),[10 90])+[0 1e-3]);
linkaxes([ax1,ax2],'xy')

sprintf(slowDelayCmd, delay)

end

