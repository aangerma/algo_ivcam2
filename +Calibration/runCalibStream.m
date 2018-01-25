function runCalibStream(configFldr,verbose)
if(~exist('verbose','var'))
    verbose=true;
end
fprintff = @(str) verbose&&fprintf(str);
calibfn = fullfile(configFldr,filesep,'calib.csv');
if(exist(calibfn,'file'))
    filedate = @(f) f.datenum;
    filedate(dir('D:\data\ivcam20\exp\20180101\config.csv'))
     movefile(calibfn,[calibfn datestr(filedate(dir(calibfn)),'yyyyMMdd_hhmm')]);
end
fprintff('Loading Firmware...');
fw=Firmware(configFldr);
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
fw.setRegs('JFILbypass',true);
d=hw.getframe();
ir12=(uint16(d.i)+bitshift(uint16(d.c),8));
glohi=minmax(ir12(:)).*[.8 1.5];
multFact = 2^12/diff(glohi);
gammaRegs.DIGG.gammaScale=bitshift(int16([round(multFact) 1]),10);
gammaRegs.DIGG.gammaShift=int16([-round(glohi(1)*multFact) 0]);
fw.setRegs(gammaRegs,calibfn);
%% ::calibrate gamma curve::

%% ::calibrate DDFZ::
fprintff('::DDFZ calibration::\n');
udistLUT=zeros(1024,1,'uint32');
regs = fw.get();
for i=1:3
    %distortion
    d=hw.getframe();
    [udistLUTinc,e]=Calibration.aux.undistFromImg(d.i,verbose);
    fprintff('#%d error: %f\n',i,e);
    udistLUT = typecast(typecast(udistLUT,'single')+typecast(udistLUTinc,'single'),'uint32');
    undistfn = fullfile(configFldr,filesep,'FRMWundistModel.bin32');
    io.writeBin(undistfn,udistLUT);
    fw.setLut(undistfn);
    hw.write('undistModel');
    %delay-fov-zenith
    d=hw.getframe();
    calibregs=Calibration.aux.calibDFZ(d,regs);
    fw.setRegs(calibregs);
    regs=hw.write();
end
fprintff('done\n');

end