function [] = setModRef(hw,valueDec,laserValInPercent)
%% modulation ref info
if exist('laserValInPercent','var')&& laserValInPercent
    valueHex = dec2hex(valueDec);
    hw.cmd(['AMCSET 5 ' num2str(valueHex)]);
    [~,RegvalDec] = Calibration.aux.RegistersReader.getRegVal(hw, '50', '0', 'control');
else
    startAddress='E20A';
    endAddress='01';
    protocol='i2c';
    bitRange=[0,5];
    Calibration.aux.RegistersReader.setRegVal(hw, startAddress, endAddress, protocol, bitRange, valueDec);
    [~,RegvalDec] =  Calibration.aux.RegistersReader.getRegValInBitRng(hw,  startAddress,endAddress,protocol,bitRange);
end
if RegvalDec~= valueDec
    error('Failed setting modulation ref register');
end
end

