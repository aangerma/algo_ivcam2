%% This script will set the maximal resolution (256) of the rtdOverX fix 
% It should divide the image region into N sections

% 1. I will activate the loop with 0 for all sections and take an average
% image.
% 2. I will activate the loop with varing values - i*dR and take average
% image
% 3. The differences will give me a map of what sections corresponds to the
% configured values.
% 4. The fix function over x should be sampled at the center of each
% section. Since it is defined for X,Y, we should transform the pixels back
% to angles and then apply the fix.

N = 10;
hw = HWinterface;
hw.cmd('dirtybitbypass');
hw.startStream();
% Config 2 zero:
hw.setReg('JFILinvBypass',1);
hw.shadowUpdate;

delayValues = zeros(1,N,'single');
cmdstr = ['CONFIG_SYSDELAY_DATA ',dec2hex(N),' ',strjoin(single2hex(delayValues),' ')];
hw.cmd(cmdstr);
frames0 = hw.getFrame(50);

delayValues = -single(1:N)*100;
cmdstr = ['CONFIG_SYSDELAY_DATA ',dec2hex(N),' ',strjoin(single2hex(delayValues),' ')];
hw.cmd(cmdstr);
framesSteps = hw.getFrame(50);




