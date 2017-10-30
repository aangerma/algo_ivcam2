function [regs] = getPersonalRegs()

% REGS SET
regs.FRMW.xres = uint16(640);
regs.FRMW.yres = uint16(480);
regs.JFIL.dnnBypass = false;
regs.JFIL.innBypass = false;

% Confidence Regs
regs.DEST.confIRbitshift = uint8(6); % confIRbitshift determines which 6 bits to use from the 
regs.DEST.confw1 = [int8(30),int8(0),int8(127),int8(-56)]; % Calculated scaled weights value. 
regs.DEST.confw2 = [int8(0),int8(0),int8(0),int8(0)]; % Other weights path should be ignored.
regs.DEST.confv = [int8(0),int8(0),int8(0),int8(0)]; % All biases are zero.
regs.DEST.confq = [int8(1),int8(0)];% Keep the first channel. Zero the second.
dt = int16(13419); x0 = int16(-3528); % Activation maps [minPrev,maxPrev]->[-128,127]. dt and 
regs.DEST.confactIn = [x0,dt];
dt = int16(255); x0 = int16(-128);% Activation maps [-128,127]->[0,255]. dt and x0 are calculated 
regs.DEST.confactOt = [x0,dt];
% dnn regs
regs = dNNRegs(regs);

end