function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta)

[regs,autogenRegs,autogenLuts] = generalRegisters(regs,autogenRegs,autogenLuts);
luts = Firmware.mergeRegs(luts,autogenLuts);
[regs,autogenRegs,autogenLuts] = Pipe.DIGG.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.RAST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.DCOR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.DEST.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.CBUF.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.JFIL.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.PCKR.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.STAT.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);
[regs,autogenRegs,autogenLuts] = Pipe.INFC.FRMW.bootCalcs(regs,luts,autogenRegs,autogenLuts,RegMeta);

end

function [regs,autogenRegs,autogenLuts] = generalRegisters(regs,autogenRegs,autogenLuts)
speedOfLightMMnsec = 299702547*1000/1e9;


autogenRegs.GNRL.tmplLength = uint16(double(regs.GNRL.codeLength)*double(regs.GNRL.sampleRate));
autogenRegs.GNRL.zNorm = single(bitshift(1,regs.GNRL.zMaxSubMMExp));
autogenRegs.EXTL.auxPItxCode=regs.FRMW.txCode;
autogenRegs.EXTL.auxPItxCodeLength=uint32(regs.GNRL.codeLength);
hfClk = regs.FRMW.pllClock/4;
autogenRegs.FRMW.sampleDist =[1 2 4]./single(regs.GNRL.sampleRate)*speedOfLightMMnsec/hfClk;

regs = FirmwareBase.mergeRegs(regs,autogenRegs);
if regs.FRMW.fovExpanderValid
    fovExpanderLut.FRMW.fovExpander = createFeLut();
    autogenLuts = Firmware.mergeRegs(autogenLuts,fovExpanderLut);
end
end

function fovExpanderLut = createFeLut()
current_dir = mfilename('fullpath');
ix = strfind(current_dir, '\');
path = fullfile(current_dir(1:ix(end)-1), '..\scripts\IV2calibTool\calibParams.xml');
calibParams = xml2structWrapper(path);
fovExpanderLut = typecast(reshape(single(calibParams.fovExpander.table), length(calibParams.fovExpander.table)*2,1),'uint32');
end