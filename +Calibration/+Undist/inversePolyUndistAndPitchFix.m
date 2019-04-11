function [ preUndistAngx,preUndistAngy ] = inversePolyUndistAndPitchFix( angx,angy,regs )
[ preUndistAngx ] = Calibration.Undist.inversePolyUndist( angx,regs );

preUndistAngy = angy - preUndistAngx/2047*regs.FRMW.pitchFixFactor;

end