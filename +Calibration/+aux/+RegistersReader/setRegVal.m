function [stat] = setRegVal(hw, startAddress, endAddress, protocol, bitRange, val)
switch protocol
    case 'memRead'
        [val_hex] =  Calibration.aux.RegistersReader.calcRegValsHex(hw, startAddress, endAddress, protocol, bitRange, val);        
        s = hw.cmd(['MWD ' startAddress ' ' endAddress ' ' val_hex]);
    case 'i2c'
        [val_hex] =  Calibration.aux.RegistersReader.calcRegValsHex(hw, startAddress, endAddress, protocol, bitRange, val);     
        val_hex=val_hex(end-1:end);
        s = hw.cmd(['iwb ' startAddress(1:2) ' ' startAddress(3:end) ' ' endAddress ' ' val_hex]);
    otherwise
        error(['Unrecognized protocol -> ' num2str(protocol)]);
end
hw.shadowUpdate();
pause(0.5);
stat = sscanf(s,'%s');
end