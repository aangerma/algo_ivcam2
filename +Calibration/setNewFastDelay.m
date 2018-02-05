function [imgBefore,imgAfter] = setNewFastDelay(hw, delay)

hw.runCommand('mwd a00e1b24 a00e1b28 00000001 //JFILsort1bypassMode');
hw.runCommand('mwd a00e084c a00e0850 00000001 //DESTaltIrEn');
hw.shadowUpdate();

frame = hw.getFrame();
imgBefore = double(frame.i);

hw.stopStream();
pause(0.1);     
    
fastDelayCmdMul8 = 'mwd a0050548 a005054c %08x // RegsProjConLocDelay';
fastDelayCmdSub8 = 'mwd a0050458 a005045c %08x // RegsProjConLocDelayHfclkRes';

mod8 = mod(delay,8);
hw.runCommand(sprintf(fastDelayCmdMul8, delay - mod8));
hw.runCommand(sprintf(fastDelayCmdSub8, mod8));
    
hw.shadowUpdate();
    
hw.restartStream();
pause(0.2);
    
frame = hw.getFrame();
imgAfter = double(frame.i);

figure(21712);
ax1 = subplot(1,2,1); imagesc(imgBefore, prctile_(imgBefore(imgBefore~=0),[10 90])+[0 1e-3]);
ax2 = subplot(1,2,2); imagesc(imgAfter, prctile_(imgAfter(imgAfter~=0),[10 90])+[0 1e-3]);
linkaxes([ax1,ax2],'xy')

sprintf(fastDelayCmdMul8, delay - mod8)
sprintf(fastDelayCmdSub8, mod8)


end

