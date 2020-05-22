function saveDSMParamsRaw(outputBinFilesPath, binWithHeaders, acDataBin, calibDataBin, dsmRegs)

dsmRegs.dsmYoffset = typecast(uint32(dsmRegs.dsmYoffset),'single');
dsmRegs.dsmXoffset = typecast(uint32(dsmRegs.dsmXoffset),'single');
dsmRegs.dsmYscale = typecast(uint32(dsmRegs.dsmYscale),'single');
dsmRegs.dsmXscale = typecast(uint32(dsmRegs.dsmXscale),'single');

DSM_params = [acDataBin ... 
             typecast((dsmRegs.dsmXscale), 'uint8') ... 
             typecast((dsmRegs.dsmYscale), 'uint8') ... 
             typecast((dsmRegs.dsmXoffset), 'uint8') ... 
             typecast((dsmRegs.dsmYoffset), 'uint8')];
        
%       calibDataBin ...
%     ];
 
mkdirSafe(outputBinFilesPath);
fullname = fullfile(outputBinFilesPath,'DSM_params');
f = fopen(fullname,'w');
fwrite(f,(vec(DSM_params)),'uint8');
fclose(f);
end
