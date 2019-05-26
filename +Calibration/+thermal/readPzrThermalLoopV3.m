function [PzrThermalLoopStruct]  = readPzrThermalLoopV3(hw)

%time, Vb, Ib, 1stlpf, S, error, 2ndLPF, PI_command, IbOut
PZR1Offset = 0;
PZR2Offset = 10;
PZR3Offset = 20;

timeOffset = 1;
vbiasOffset = 2;
iBiasOffset = 3;
firstFilterOffset = 4;
sensitivityOffset = 5;
errorOffset = 6;
secondFilterOffset = 7;
piCmdOffset = 8;
IbOutOffset = 9;
ErrorAfterJitterOffset = 10;

timeUnits = 1e-6;

% pzrThermalLoopStructAddress = '5d000';

% Read all 3 PZRs data structure
dataStr = hw.cmd('mrd 5d000 5d078');
dataSplit = split(dataStr);
valids = cellfun(@all,isstrprop(dataSplit,'xdigit'));
% ~isnan(str2double(dataSplit));
data = dataSplit(valids);
% data=readMulRegHWM(pzrThermalLoopStructAddress, 30, cmdMngr);

% Parse the data structure for PZR1
PzrThermalLoopStruct.PZR1.time = hex2single(char(data(PZR1Offset + timeOffset))) * timeUnits;
PzrThermalLoopStruct.PZR1.Vbias = hex2single(char(data(PZR1Offset + vbiasOffset)));
PzrThermalLoopStruct.PZR1.Ibias = hex2single(char(data(PZR1Offset + iBiasOffset)));
PzrThermalLoopStruct.PZR1.firstLpf = hex2single(char(data(PZR1Offset + firstFilterOffset)));
PzrThermalLoopStruct.PZR1.sensitivity = hex2single(char(data(PZR1Offset + sensitivityOffset)));
PzrThermalLoopStruct.PZR1.Error = hex2single(char(data(PZR1Offset + errorOffset)));
PzrThermalLoopStruct.PZR1.secondLpf = hex2single(char(data(PZR1Offset + secondFilterOffset)));
PzrThermalLoopStruct.PZR1.PIcmd = hex2single(char(data(PZR1Offset + piCmdOffset)));
PzrThermalLoopStruct.PZR1.IbOut = hex2single(char(data(PZR1Offset + IbOutOffset)));
PzrThermalLoopStruct.PZR1.ErrorAfterJitter = hex2single(char(data(PZR1Offset + ErrorAfterJitterOffset)));

% Parse the data structure for PZR2
PzrThermalLoopStruct.PZR2.time = hex2single(char(data(PZR2Offset + timeOffset))) * timeUnits;
PzrThermalLoopStruct.PZR2.Vbias = hex2single(char(data(PZR2Offset + vbiasOffset)));
PzrThermalLoopStruct.PZR2.Ibias = hex2single(char(data(PZR2Offset + iBiasOffset)));
PzrThermalLoopStruct.PZR2.firstLpf = hex2single(char(data(PZR2Offset + firstFilterOffset)));
PzrThermalLoopStruct.PZR2.sensitivity = hex2single(char(data(PZR2Offset + sensitivityOffset)));
PzrThermalLoopStruct.PZR2.Error = hex2single(char(data(PZR2Offset + errorOffset)));
PzrThermalLoopStruct.PZR2.secondLpf = hex2single(char(data(PZR2Offset + secondFilterOffset)));
PzrThermalLoopStruct.PZR2.PIcmd = hex2single(char(data(PZR2Offset + piCmdOffset)));
PzrThermalLoopStruct.PZR2.IbOut = hex2single(char(data(PZR2Offset + IbOutOffset)));
PzrThermalLoopStruct.PZR2.ErrorAfterJitter = hex2single(char(data(PZR2Offset + ErrorAfterJitterOffset)));

% Parse the data structure for PZR3
PzrThermalLoopStruct.PZR3.time = hex2single(char(data(PZR3Offset + timeOffset))) * timeUnits;
PzrThermalLoopStruct.PZR3.Vbias = hex2single(char(data(PZR3Offset + vbiasOffset)));
PzrThermalLoopStruct.PZR3.Ibias = hex2single(char(data(PZR3Offset + iBiasOffset)));
PzrThermalLoopStruct.PZR3.firstLpf = hex2single(char(data(PZR3Offset + firstFilterOffset)));
PzrThermalLoopStruct.PZR3.sensitivity = hex2single(char(data(PZR3Offset + sensitivityOffset)));
PzrThermalLoopStruct.PZR3.Error = hex2single(char(data(PZR3Offset + errorOffset)));
PzrThermalLoopStruct.PZR3.secondLpf = hex2single(char(data(PZR3Offset + secondFilterOffset)));
PzrThermalLoopStruct.PZR3.PIcmd = hex2single(char(data(PZR3Offset + piCmdOffset)));
PzrThermalLoopStruct.PZR3.IbOut = hex2single(char(data(PZR3Offset + IbOutOffset)));
PzrThermalLoopStruct.PZR3.ErrorAfterJitter = hex2single(char(data(PZR3Offset + ErrorAfterJitterOffset)));

end