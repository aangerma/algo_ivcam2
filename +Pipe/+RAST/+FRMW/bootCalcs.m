function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)


binSize3=...
regs.GNRL.imgVsize > 240 & regs.GNRL.imgVsize <= 480 & regs.GNRL.tmplLength > 476 & regs.GNRL.tmplLength <= 832 |...
regs.GNRL.imgVsize > 480 & regs.GNRL.imgVsize <= 960 & regs.GNRL.tmplLength > 230 & regs.GNRL.tmplLength <= 416;
if(binSize3)
autogenRegs.RAST.cmaBinSize = uint8(3);
else
autogenRegs.RAST.cmaBinSize = uint8(5);
end




%3:6
denomDiv = double(regs.GNRL.tmplLength)./[8 16 32 64];
dInv = find(rem(denomDiv,1)==0,1,'last');
if(isempty(dInv))
%     Illegal code length
    dInv=1;
end
autogenRegs.RAST.sharedDenomExp=uint8(dInv+2);

autogenRegs.RAST.sharedDenom = 2^autogenRegs.RAST.sharedDenomExp;
autogenRegs.RAST.cmaMaxSamples = 2^autogenRegs.RAST.cmaBinSize-1;


dcCodeNorm = uint16(single(2^22)/single(regs.GNRL.tmplLength));
autogenRegs.RAST.dcCodeNorm = dcCodeNorm;

%codeNorm =typecast(newRegs.RAST.dcCodeNorm,'uint64');
%codeNorm = newRegs.RAST.dcCodeNorm;

regs = Firmware.mergeRegs(regs,autogenRegs);

end

