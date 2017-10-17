function calibRegs=runcalibPipe(varargin)

p = inputHandler(varargin{:});
fw = Firmware();
fw.setRegs(p.modeFile);

regs = fw.get();
ivs = io.readIVS(p.ivsFilename);
%%


%% slow/fast delays
 [fd,sd] = Calibration.aux.mSyncerPipe(ivs,regs,p.verbose);
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
%% RX gain
% [regs,luts] = fw.get();
% pout = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);

% 
% outregs.FRMW.xfov = single(xFOV);
% outregs.FRMW.yfov = single(yFOV);
% outregs.FRMW.xoffset = single(xoffset);
% outregs.FRMW.yoffset = single(yoffset);
% outregs.FRMW.xfov = 20;
% outregs.FRMW.yfov = 28;
% outregs.FRMW.xoffset = 0.7;
% outregs.FRMW.yoffset = 0;
% 
% outregs.DEST.baseline = 0;
    fw.setRegs(calibRegs,p.calibFile);
    fw.writeUpdated(p.calibFile);

basedir=fileparts(p.calibFile)	;
io.writeBin(fullfile(basedir,'FRMWxLensModel.bin32'),opticalLuts.FRMW.xLensModel);
io.writeBin(fullfile(basedir,'FRMWyLensModel.bin32'),opticalLuts.FRMW.yLensModel);
	
end

function p = inputHandler(ivsFilename,varargin)
%% defs

[basedir] = fileparts(ivsFilename);
defs.verbose = true;
defs.modefn = fullfile(basedir,filesep,'mode.csv');
defs.calibfn = fullfile(basedir,filesep,'calib.csv');


%% varargin parse
p = inputParser;

isfile = @(x) exist(x,'file');
isflag = @(x) or(isnumeric(x),islogical(x));

addOptional(p,'verbose',defs.verbose,isflag);
addOptional(p,'modeFile',defs.modefn,isfile);
addOptional(p,'calibFile',defs.calibfn);
parse(p,varargin{:});

p = p.Results;

p.ivsFilename = ivsFilename;
%remove " from filename;
p.ivsFilename(p.ivsFilename=='"')=[];
%create output dir(s)


end