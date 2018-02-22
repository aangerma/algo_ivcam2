function evaluateDODCalib(hw,fnAlgoCalib,resDODParams)
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
[regs,luts] = resDODParams.fw.get();
[~,eAlex,eFit,~] = Calibration.aux.calibDFZ(d,regs,0,[regs.FRMW.gaurdBandH,regs.FRMW.gaurdBandV],true);
% Calc distortion Error
[~,eDist,~] = Calibration.aux.undistFromImg(d.i,0);

fprintf('[*] DOD Final Scores:\n - eAlex = %2.2fmm\n - eFit = %2.2fmm\n - eDistortion = %2.2fmm\n',eAlex,eFit,eDist);


end

