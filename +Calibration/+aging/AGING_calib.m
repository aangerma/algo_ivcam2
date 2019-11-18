function [agingRegs,results] = AGING_calib(hw, calibParams, results, fprintff, t);
r = AGING_calib_Init(hw);
z2mm = single(hw.z2mm);
res = hw.streamSize;
DACVoltage = dec2hex(calibParams.aging.DAC);

for i = 1:size(DACVoltage,1)
    
    %change voltage
    hw.cmd('mwd a0040004 a0040008 FFF');
    hw.cmd(sprintf('%s %s', 'mwd a0040078 a004007c', DACVoltage(i,:)));
    hw.cmd('mwd a0040074 a0040078 1');
    hw.cmd('mwd a0010100 a0010104 1020003F');
    %get volatge
    for k = 1:calibParams.aging.nreadsToAverage
        hw.cmd('mwd b00a00c4 b00a00c8 19E662bC');
        voltSamples{i,k} = hw.cmd('MRD4 b00a00c8');
    end
    %     voltD(i) = (hex2dec(volt(end-2:end))+1157.2)/1865.8;
    pause(1);
    frameBytes{i} = Calibration.aux.captureFramesWrapper(hw, 'Z', calibParams.aging.nFramesToAverage);
end

[agingRegs,agingResults] = RtdOverAging_Calib_Calc(frameBytes, calibParams, res, z2mm, voltSamples);

results.vddVoltageRange = agingResults.vddVoltageRange;
results.vddDistanceRange = agingResults.vddDistanceRange;

r.reset();
end

function [r] = AGING_calib_Init(hw)

r=Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.add('DESTdepthAsRange',true);
r.add('DIGGsphericalEn',true);
r.set();
end