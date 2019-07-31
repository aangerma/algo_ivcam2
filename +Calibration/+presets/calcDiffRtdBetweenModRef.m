function [diffRtdBetweenModRef]= calcDiffRtdBetweenModRef(hw,maxMod_dec,maxRangeScaleModRef,cameraInput,calibParams)
maskParams = calibParams.presets.long.params;

b=hw.read('DESTbaseline');
b2=hw.read('DESTbaseline2');
znorm=cameraInput.z2mm;
r=Calibration.RegState(hw);

r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.add('DESTbaseline',single(0));
r.add('DESTbaseline2',single(0));
r.set();

Calibration.aux.RegistersReader.setModRef(hw,maxMod_dec);
pause(3);
maxModFrames=hw.getFrame(10,true); 
Calibration.aux.RegistersReader.setModRef(hw,round(maxMod_dec*maxRangeScaleModRef));
pause(3);
scaledModFrames=hw.getFrame(10,true); 

mask = Validation.aux.getRoiCircle(cameraInput.imSize, maskParams);
diffRtdBetweenModRef=mean(2*scaledModFrames.z(mask)./znorm)-mean(2*maxModFrames.z(mask)./znorm);

% return to previous values
r=Calibration.RegState(hw);
r.add('DESTdepthAsRange',false);
r.add('DIGGsphericalEn',false);
r.add('DESTbaseline',single(b));
r.add('DESTbaseline2',single(b2));
r.set();
end