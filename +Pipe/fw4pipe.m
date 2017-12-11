function [fw,regs,luts] = fw4pipe(p)

fw = Firmware();
fw.setRegHandle(p.regHandle);





if(~exist(p.modeFile,'file'))
    error('Could not find mode file (%s)',p.modeFile);
end
fw.setRegs(p.modeFile);

if(exist(p.configFile,'file'))
    fw.setRegs(p.configFile);
end


if(exist(p.calibFile,'file'))
    fw.setRegs(p.calibFile);
else
    %------------CALIBRATION BEGIN------------
    calibTic=tic; lgr.print('\n\t\tCalibrating...');
    Calibration.runcalibPipe(p.ivsFilename,'calibFile',p.calibFile,'modeFile',p.modeFile);
    lgr.print(' done in %4.2f sec \n', toc(calibTic));
    %------------CALIBRATION END------------
end
dnnWeightFile = fullfile(fileparts(p.calibFile),'dnnweights.csv');
innWeightFile = fullfile(fileparts(p.calibFile),'innweights.csv');
xlensMdlFile = fullfile(fileparts(p.calibFile),'FRMWxlensModel.bin32');
ylensMdlFile = fullfile(fileparts(p.calibFile),'FRMWylensModel.bin32');
if(exist(dnnWeightFile,'file'))
    fw.setRegs(dnnWeightFile);
end

if(exist(innWeightFile,'file'))
    fw.setRegs(innWeightFile);
end

if(exist(xlensMdlFile,'file'))
    fw.setLut(xlensMdlFile);
end
if(exist(ylensMdlFile,'file'))
    fw.setLut(ylensMdlFile);
end


if(p.rewrite)
    fw.writeUpdated(p.configFile);
    fw.writeUpdated(p.modeFile);
    fw.writeUpdated(p.calibFile);
end

%%% tmund write my own regs %%%
% perosnalRegs = getPersonalRegs();
% fw.setRegs(perosnalRegs,p.configFile);
% fw.writeUpdated(p.configFile);
% calibFilename = fullfile(p.outputDir,filesep,'calib.csv');
% fid=fopen(calibFilename,'w');
% fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[regs,luts] = fw.get();


%register overide
if(p.debug~=-1)
    regs.MTLB.debug=p.debug;
end
if(p.fastApprox~=-1)
    regs.MTLB.fastApprox=dec2bin(uint8(p.fastApprox),8);
end


end