function [] = setModRef(hw,valueDec)
%% modulation ref info
startAddress='E20A';
endAddress='01';
protocol='i2c';
bitRange=[0,5];
Calibration.aux.RegistersReader.setRegVal(hw, startAddress, endAddress, protocol, bitRange, valueDec);
[~,RegvalDec] =  Calibration.aux.RegistersReader.getRegValInBitRng(hw,  startAddress,endAddress,protocol,bitRange);
if RegvalDec~= valueDec
    error('Failed setting modulation ref register');
end
end

