function calibRegs=runcalibPipe(varargin)

[fw,p] = Pipe.loadFirmware(varargin{:});

regs = fw.get();
ivs = io.readIVS(p.ivsFilename);
%%


%% slow/fast delays
 [fd,sd] = Calibration.aux.mSyncerPipe(ivs,regs,true,p.verbose);
fprintf('MTLBfastChDelay = %d\n',fd);
fprintf('MTLBslowChDelay = %d\n',sd);
calibRegs.MTLB.fastChDelay=uint32(fd);
calibRegs.MTLB.slowChDelay=uint32(sd);
calibRegs.DEST.txFRQpd=single([0 0 0 ]);
fw.setRegs(calibRegs,p.calibFile);
%%
% calibRegs.FRMW.xres=uint16(320);
% calibRegs.FRMW.yres=uint16(240);
% 
% [regs,luts] = fw.get();
% pout = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
% 
% img = pout.rImg;
% xyc=size(img)/2;
% r0=nanmean(vec(img(xyc(1)+(-100:100),xyc(2)+(-100:100))));
% calibRegs.DEST.txFRQpd=single([1 1 1]*(r0-p.gtDistanceMM)*2);
% fprintf('DESTtxFRQpd = %f\n',calibRegs.DEST.txFRQpd);
% fw.setRegs(calibRegs,p.calibFile);
%% FOV
[optcalibRegs,opticalLuts] = Calibration.aux.findOpticalSetupParam(ivs,fw);
calibRegs=Firmware.mergeRegs(calibRegs,optcalibRegs);
fw.setRegs(calibRegs,p.calibFile);
fw.writeUpdated(p.calibFile);

basedir=fileparts(p.calibFile)	;
io.writeBin(fullfile(basedir,'FRMWundistModel.bin32'),opticalLuts.FRMW.undistModel);
	
end
% 
% function p = inputHandler(ivsFilename,varargin)
% %% defs
% 
% [basedir] = fileparts(ivsFilename);
% defs.verbose = true;
% defs.modefn = fullfile(basedir,filesep,'mode.csv');
% defs.calibfn = fullfile(basedir,filesep,'calib.csv');
% 
% 
% %% varargin parse
% p = inputParser;
% 
% isfile = @(x) exist(x,'file');
% isflag = @(x) or(isnumeric(x),islogical(x));
% 
% addOptional(p,'verbose',defs.verbose,isflag);
% addOptional(p,'modeFile',defs.modefn,isfile);
% addOptional(p,'calibFile',defs.calibfn);
% parse(p,varargin{:});
% 
% p = p.Results;
% 
% p.ivsFilename = ivsFilename;
% %remove " from filename;
% p.ivsFilename(p.ivsFilename=='"')=[];
% %create output dir(s)
% 
% 
% end