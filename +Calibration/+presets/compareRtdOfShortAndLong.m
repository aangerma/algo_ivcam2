function results = compareRtdOfShortAndLong(hw,calibParams,res,runParams)

% Init stage
z2mm = single(hw.z2mm);
N = calibParams.presets.compare.nTrials;
for i = 1:N
    for p = 1:2
        hw.stopStream;
        hw.setPresetControlState(p);
        hw.startStream(0,res);
        r=Calibration.RegState(hw);
        r.add('JFILinvBypass',true);
        r.add('DESTdepthAsRange',true);
        r.add('DESTbaseline$',single(0));
        r.add('DESTbaseline2$',single(0));
        r.set();
        hw.getFrame(30);       
        depthData{i,p} = captureFramesWrapper(hw, 'Z', calibParams.presets.compare.nFrames);
    end
end
hw.stopStream;
results = PresetsAlignment_Calib_Calc(depthData,calibParams,res,z2mm);

end