function [val_hex,val_dec] = getRegVal(hw, startAddress, endAddress, protocol)
switch protocol
    case 'memRead'
        s = hw.cmd(['MRD ' startAddress ' ' endAddress]);
    case 'i2c'
        s = hw.cmd(['irb ' startAddress(1:2) ' ' startAddress(3:end) ' ' endAddress]);
    case 'control'
        s = hw.cmd(['AMCGET ' startAddress(1) ' ' startAddress(2) ' ' endAddress]);
    otherwise
        error(['Unrecognized protocol -> ' num2str(protocol)]);
end
val_hex = sscanf(s,'Address: %*s => %s');
val_dec = hex2dec(val_hex); 
end

