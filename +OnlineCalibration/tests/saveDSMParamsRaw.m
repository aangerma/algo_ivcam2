function saveDSMParamsRaw(outputBinFilesPath, binWithHeaders, acDataBin, regs, dsmRegs)

% dsmRegs.dsmYoffset = typecast(uint32(dsmRegs.dsmYoffset),'single');
% dsmRegs.dsmXoffset = typecast(uint32(dsmRegs.dsmXoffset),'single');
% dsmRegs.dsmYscale = typecast(uint32(dsmRegs.dsmYscale),'single');
% dsmRegs.dsmXscale = typecast(uint32(dsmRegs.dsmXscale),'single');


if binWithHeaders
   headerSize = 16;
   acDataBin = acDataBin(headerSize+1:end);
end

DSM_params = [  acDataBin ... 
                typecast(double(dsmRegs.dsmXscale), 'uint8') ... 
                typecast(double(dsmRegs.dsmYscale), 'uint8') ... 
                typecast(double(dsmRegs.dsmXoffset), 'uint8') ... 
                typecast(double(dsmRegs.dsmYoffset), 'uint8') ...
                int8(regs.FRMW.fovexExistenceFlag )...
                typecast((regs.FRMW.fovexNominal ),'uint8')...
                typecast((regs.FRMW.laserangleH ),'uint8')...
                typecast((regs.FRMW.laserangleV ),'uint8')...
                typecast((regs.FRMW.xfov ),'uint8')...
                typecast((regs.FRMW.yfov ),'uint8')...
                typecast((regs.FRMW.polyVars ),'uint8')...
                typecast((regs.FRMW.undistAngHorz ),'uint8')...
                typecast((regs.FRMW.pitchFixFactor ),'uint8')...
             ];
        
mkdirSafe(outputBinFilesPath);
fullname = fullfile(outputBinFilesPath,'DSM_params');
f = fopen(fullname,'w');
fwrite(f,(vec(DSM_params)),'uint8');
fclose(f);
end