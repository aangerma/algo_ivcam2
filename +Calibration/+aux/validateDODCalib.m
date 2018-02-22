function errGeom = validateDODCalib(hw, fnAlgoCalib, resDODParams, fprintff, verbose)
% disable algo pipe
hw.runCommand('mwd a0010100 a0010104 11200000  // pmg_pmg. RegsPmgDepthEn        -  close algo pipe, but keep usb on');
% Set resulting configuration
hw.runScript(fnAlgoCalib);
% Apply shadow update
hw.shadowUpdate();
% enable algo pipe
hw.runCommand('mwd a0010100 a0010104 1120003f //[m_regmodel.pmg_pmg.RegsPmgDepthEn] TYPE_REG');
% Read average of 30 frames
d = Calibration.aux.readAvgFrame(hw,30);
% Calc Geometric Error
[regs, ~] = resDODParams.fw.get();
[~,errGeom,errFit,~] = Calibration.aux.calibDFZ(d,regs,0,[regs.FRMW.gaurdBandH,regs.FRMW.gaurdBandV],true);
% Calc distortion Error
[~,errDist,~] = Calibration.aux.undistFromImg(d.i,0);

if (verbose)
    fprintff('[*] DOD Validation Scores:\n - eGeom = %2.2fmm\n - eFit = %2.2fmm\n - eDistortion = %2.2fmm\n',errGeom,errFit,errDist);
end


end

