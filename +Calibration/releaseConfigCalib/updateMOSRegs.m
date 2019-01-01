currdir = fileparts(mfilename('fullpath'));
fs = dir(fullfile(currdir,'..','initConfigCalib','*.csv'));

for i = 1:numel(fs)
    sourcePath = fullfile(fs(i).folder,fs(i).name);
    destPath = fullfile(currdir,fs(i).name);
    copyfile(sourcePath, destPath); 
end
% MOS configuration from Vitaly
sort_bypass_mode = 0;
JFIL_sharpS = 0;
JFIL_sharpR = 12;
RAST_sharpS = 0;
RAST_sharpR = 2;

regs.JFIL.bilt1bypass = uint8(0);
regs.JFIL.bilt2bypass = uint8(0);
regs.JFIL.bilt3bypass = uint8(0);

regs.RAST.biltAdapt = uint8(0);
regs.JFIL.biltAdaptR = uint8(0);
regs.JFIL.biltAdaptS = uint8(0);
regs.JFIL.biltIRAdaptS = uint8(0);

regs.RAST.biltSharpnessS = uint8(RAST_sharpS);
regs.RAST.biltSharpnessR = uint8(RAST_sharpR);

regs.JFIL.sort1bypassMode = uint8(sort_bypass_mode);
regs.JFIL.sort2bypassMode = uint8(sort_bypass_mode);
regs.JFIL.sort3bypassMode = uint8(sort_bypass_mode);

regs.JFIL.biltSharpnessS = uint8(JFIL_sharpS);
regs.JFIL.bilt1SharpnessR = uint8(JFIL_sharpR);
regs.JFIL.bilt2SharpnessR = uint8(JFIL_sharpR);
regs.JFIL.bilt3SharpnessR = uint8(JFIL_sharpR);

fw = Pipe.loadFirmware(currdir);
fw.setRegs(regs,fullfile(currdir,'config.csv'));
fw.get();
fw.writeUpdated(fullfile(currdir,'config.csv'));