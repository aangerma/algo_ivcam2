function score=runCalibStream(configFldr,outputFolder,fprintff,verbose)
if(~exist('verbose','var'))
    verbose=true;
end
% fprintff = @(varargin) verbose&&fprintf(varargin{:});

fprintff('Loading Firmware...',false);
fw=Pipe.loadFirmware(configFldr);
fprintff('Done',true);
fprintff('Connecting HW interface...');
hw=HWinterface(fw);
fprintff('Done',true);
%% ::calibrate delays::
fprintff('Depth delay calibration...',false);

fprintff('Done',true);

fprintff('IR delay calibration...',false);


fprintff('Done',true);


fprintff('XY delay calibration...',false);

fprintff('Done',true);

%% ::calibrate gamma scale shift::
% fw.setRegs('JFILbypass',false);
% fw.setRegs('JFILbypassIr2Conf',true);
% hw.write('JFILbypass|JFILbypassIr2Conf');
% d=hw.getFrame();
%%
% ir12=(uint16(d.i)+bitshift(uint16(d.c),8));
% glohi=minmax(ir12(:)).*[.8 1.5];
% multFact = 2^12/diff(glohi);
% gammaRegs.DIGG.gammaScale=bitshift(int16([round(multFact) 1]),10);
% gammaRegs.DIGG.gammaShift=int16([-round(glohi(1)*multFact) 0]);
% fw.setRegs(gammaRegs,calibfn);
%% ::calibrate gamma curve::

%% ::Get image::

fprintff('DDFZ init...',false);


luts.FRMW.undistModel=zeros(2048,1,'uint32');
fw.setLut(luts);
resetregs.DIGG.undistBypass=false;
resetregs.DEST.txFRQpd=single([0 0 0]);
fw.setRegs(resetregs,[]);
hw.write();
fprintff('Done',true);
for i=1:30
    d_=hw.getFrame();
end

fprintff('DDFZ calibration...',false);

collapseM = @(x) median(reshape([d_.(x)],size(d_(1).(x),1),size(d_(1).(x),2),[]),3);
d.z=collapseM('z');
d.i=collapseM('i');
d.c=collapseM('c');




[~,~,irNew]=Calibration.aux.calibDFZ(d,regs,verbose);
[udistLUTinc,~,undistF]=Calibration.aux.undistFromImg(irNew,1);
luts.FRMW.undistModel = typecast(typecast(luts.FRMW.undistModel,'single')+typecast(udistLUTinc,'single'),'uint32');
d.z=undistF(d.z);
d.i=undistF(d.i);
d.c=undistF(d.c);
[outregs,minerr]=Calibration.aux.calibDFZ(d,regs,verbose);



fprintff('Done',true);
score=minerr;

fprintff('[*] Score: %g',minerr,true);




calibfn = fullfile(outputFolder,filesep,'calib.csv');
undistfn=fullfile(outputFolder,filesep,'FRMWundistModel.bin32');
io.writeBin(undistfn,luts.FRMW.undistModel)
fw.setRegs(outregs,calibfn);
fw.writeUpdated(calibfn)
fprintff('done\n');
fw.genMWDcmd([],fullfile(outputFolder,filesep,'algoConfig.txt'));
end

