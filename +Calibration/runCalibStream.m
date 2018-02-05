function runCalibStream(configFldr,verbose)
if(~exist('verbose','var'))
    verbose=true;
end
fprintff = @(varargin) verbose&&fprintf(varargin{:});
calibfn = fullfile(configFldr,filesep,'calib.csv');
if(exist(calibfn,'file'))
    filedate = @(f) f.datenum;
    filedate(dir('D:\data\ivcam20\exp\20180101\config.csv'))
     movefile(calibfn,[calibfn datestr(filedate(dir(calibfn)),'yyyyMMdd_hhmm')]);
end
fprintff('Loading Firmware...');
fw=Pipe.loadFirmware(configFldr);
fprintff('Done\nConnecting HW interface...');
hw=HWinterface(fw);
fprintff('Done\n');
%% ::calibrate delays::
fprintff('::Depth delay calibration::\n');

fprintff('done\n');

fprintff('::IR delay calibration::\n');


fprintff('done\n');


fprintff('::XY delay calibration::\n');


fprintff('done\n');
%% ::calibrate gamma scale shift::
fw.setRegs('JFILbypass',false);
fw.setRegs('JFILbypassIr2Conf',true);
hw.write('JFILbypass|JFILbypassIr2Conf');
d=hw.getFrame();
%%
% ir12=(uint16(d.i)+bitshift(uint16(d.c),8));
% glohi=minmax(ir12(:)).*[.8 1.5];
% multFact = 2^12/diff(glohi);
% gammaRegs.DIGG.gammaScale=bitshift(int16([round(multFact) 1]),10);
% gammaRegs.DIGG.gammaShift=int16([-round(glohi(1)*multFact) 0]);
% fw.setRegs(gammaRegs,calibfn);
%% ::calibrate gamma curve::

%% ::Get image::
% undistfn = fullfile(configFldr,filesep,'FRMWundistModel.bin32');
fprintff('::DDFZ calibration::\n');
fprintff('init...');
undistfn=fullfile(configFldr,filesep,'FRMWundistModel.bin32');
luts.FRMW.undistModel=zeros(2048,1,'uint32');
fw.setLut(luts);
resetregs.DIGG.undistBypass=false;
resetregs.DEST.txFRQpd=single([0 0 0]);
fw.setRegs(resetregs,[]);
hw.write('DIGGundistModel');

fprintff('done\n');
for i=1:30
d_=hw.getFrame();
end

collapseM = @(x) median(reshape([d_.(x)],size(d_(1).(x),1),size(d_(1).(x),2),[]),3);
d.z=collapseM('z');
d.i=collapseM('i');
d.c=collapseM('c');


for i=1:3
   
    [outregs,minerr,irNew]=Calibration.aux.calibDFZ(d,regs);
    regs=Firmware.mergeRegs(regs,outregs);
    
    [udistLUTinc,e,undistF]=Calibration.aux.undistFromImg(irNew,1);
    luts.FRMW.undistModel = typecast(typecast(luts.FRMW.undistModel,'single')+typecast(udistLUTinc,'single'),'uint32');
    d.z=undistF(d.z);
    d.i=undistF(d.i);
    d.c=undistF(d.c);
 
end
io.writeBin(undistfn,luts.FRMW.undistModel)
fw.setRegs(outregs,calibfn);
fw.writeUpdated(calibfn)
fprintff('done\n');
fw.genMWDcmd([],fullfile(configFldr,filesep,'algoConfig.txt'));
end

