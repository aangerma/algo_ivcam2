function evaluateAlgoCalib(hw,fnAlgoCalib,resDODParams)
% disable algo pipe
hw.runCommand('mwd a0010100 a0010104 11200000  // pmg_pmg. RegsPmgDepthEn        -  close algo pipe, but keep usb on');
% Set resulting configuration
hw.runScript(fnAlgoCalib);
% enable algo pipe
hw.runCommand('mwd a0010100 a0010104 1120003f //[m_regmodel.pmg_pmg.RegsPmgDepthEn] TYPE_REG');
% Read average of 30 frames
d = Calibration.aux.readAvgFrame(hw,30);
% Calc Geometric Error
[~,eAlex,eFit,~] = Calibration.aux.calibDFZ(d,resDODParams.regs,0,[0,0],true);
% Calc distortion Error
[~,eDist,~] = Calibration.aux.undistFromImg(d.i,0);

fprintff('[*] Final Scores:\n - eAlex = %2.2fmm\n - eFit = %2.2fmm\n - eDistortion = %2.2fmm\n',eAlex,eFit,eDist);


end

