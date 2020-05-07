% clear;
% load('C:\otherSource\InputData_correct_ac2.mat');
% load('C:\otherSource\BaseParams.mat');
% frame.i = frame_ir;
% frame.z = frame_depth;
% frame.yuy2 = frame_color;
% frame.yuy2Prev = frame_color_prev;
% 
% BaseParams.svmModelPath = 'C:\otherSource\algo_ivcam2\+OnlineCalibration\+SVMModel\SVMModel.mat';
% params = BaseParams;
% originalParams = params;
% [validParams,params,sceneResults] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams);
% 
% 
% 
% 
% %%


clear
load('C:\otherSource\InputData_with_313.mat');
load('C:\otherSource\inputExample.mat');

dsmRegs.dsmXscale = typecast(uint32(flowParams.ac2_new_inputs.extLdsmXscale),'single');
dsmRegs.dsmXoffset = typecast(uint32(flowParams.ac2_new_inputs.extLdsmXoffset),'single');
dsmRegs.dsmYscale = typecast(uint32(flowParams.ac2_new_inputs.extLdsmYscale),'single');
dsmRegs.dsmYoffset = typecast(uint32(flowParams.ac2_new_inputs.extLdsmYoffset),'single');

headerSize = 16;
binTable = uint8(cell2mat(flowParams.ac2_new_inputs.table_240));
acDataIn = Calibration.tables.convertBinTableToCalibData(binTable(2*headerSize+1:end), 'Algo_AutoCalibration');
acDataIn.flags = mod(acDataIn.flags(1),2);
binTable = uint8(cell2mat(flowParams.ac2_new_inputs.table_313));
regs = Calibration.tables.convertBinTableToCalibData(binTable(headerSize+1:end), 'Algo_Calibration_Info_CalibInfo');
regs.FRMW.rtdOverX(1:6) = 0;
regs.FRMW.rtdOverY(1:3) = 0;
regs.FRMW.mirrorMovmentMode = 1;
regs.DEST.baseline2 = regs.DEST.baseline^2;
% accPath = fileparts(accPath);
% atcPath = fileparts(atcPath);
% calData = Calibration.tables.getCalibDataFromCalPath(atcPath, accPath);
% regs = calData.regs;
% regsDEST.hbaseline = 0;
% regsDEST.baseline = -10;
% regsDEST.baseline2 = regsDEST.baseline^2;
% regs.DEST = mergestruct(regs.DEST, regsDEST);

KRaw = params.Kdepth;
KRaw(1,3) = single(params.depthRes(2))-1-KRaw(1,3);
KRaw(2,3) = single(params.depthRes(1))-1-KRaw(2,3);

optK = KRaw;
optK([1,5]) = optK([1,5])*1.01;

% acDataIn.hFactor = 1;
% acDataIn.vFactor = 1;
% acDataIn.hOffset = 0;
% acDataIn.vOffset = 0;
% acDataIn.flags = 1; % 1 - AOT model, 2 - TOA model


isValidPix = zeros(params.depthRes);
activePixels = unique(randi(prod(params.depthRes),[1,1000]));
isValidPix(activePixels) = 1;
isValidPix = logical(isValidPix);

preProcData = OnlineCalibration.K2DSM.PreProcessing(regs, acDataIn, dsmRegs, params.depthRes, KRaw);
[losShift, losScaling] = OnlineCalibration.K2DSM.ConvertKToLosError(preProcData, isValidPix, KRaw, optK);
acDataOut = OnlineCalibration.K2DSM.ConvertLosErrorToAcData(dsmRegs, acDataIn, acDataIn.flags, losShift, losScaling);
acDataOut.flags(2:6) = uint8(0);

acOutBinTable = Calibration.tables.convertCalibDataToBinTable(acDataOut, 'Algo_AutoCalibration');
