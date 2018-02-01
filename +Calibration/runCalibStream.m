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

%% ::calibrate DDFZ::
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

for i=1:3
    %zenith
    calibregs=calibZenith(hw,verbose);
    fw.setRegs(calibregs,calibfn);
    hw.write();
    %distortion
    d=hw.getFrame();
    [udistLUTinc,e]=Calibration.aux.undistFromImg(d.i,verbose);
    if(0)
        %% VALIDATE
        [diggRegs,diggLuts] = Pipe.DIGG.FRMW.buildLensLUT(regs,struct('FRMW',struct('undistModel',udistLUTinc)));
        diggRegs=FirmwareBase.mergeRegs(regs,diggRegs);
        [yg,xg]=ndgrid(0:size(d.i,1)-1,0:size(d.i,2)-1);
        f2i = @(x) int32(round(x-(mod(x,2)==.5)*0.5+(mod(x,2)==1.5)*0.5));
        shift = single(2^double(regs.DIGG.bitshift));
        xold_ = f2i (xg*shift);
        yold_ = f2i (yg*shift);
        [ xnew,ynew ] = Pipe.DIGG.undist( xold_(:),yold_(:),diggRegs,diggLuts,Logger(),[] );
        xyQout = double(Pipe.DIGG.ranger(xnew, ynew, regs));
        xyQout(1,:)=xyQout(1,:)/4;
        v=griddata(xyQout(1,:),xyQout(2,:),double(d.i(:)),xg,yg);
        [udistLUTinc,e]=Calibration.aux.undistFromImg(v,verbose);
        drawnow;
        
    end
    %%
    fprintff('#%d error: %f\n',i,e);
    luts.FRMW.undistModel = typecast(typecast(luts.FRMW.undistModel,'single')+typecast(udistLUTinc,'single'),'uint32');
    fw.setLut(luts);
    hw.write('DIGG');
    %delay-fov
    d=hw.getFrame();
    regs=fw.get();
    calibregs=Calibration.aux.calibDF(d,regs);
    fw.setRegs(calibregs,calibfn);
    hw.write();%write only update!
    
end
[~,luts]=fw.get();
io.writeBin(undistfn,luts.FRMW.undistModel)
fw.writeUpdated(calibfn)
fprintff('done\n');
fw.genMWDcmd([],fullfile(configFldr,filesep,'algoConfig.txt'));
end

function calibregs=calibZenith(hw,verbose)
x0=[0,0];
opt.maxIter=1000;
opt.OutputFcn=[];
if(verbose)
    opt.Display='iter';
end
xbest=fminsearchbnd(@(x) zenithEF(x,hw),x0,[-3 -3],[3 3],opt);
calibregs=x2regs(xbest);
end
function regs=x2regs(x)
regs.FRMW.laserangleH=single(x(1));
regs.FRMW.laserangleV=single(x(2));
end
function e = zenithEF(x,hw)
regs = x2regs(x);
fw=hw.getFrimware();
fw.setRegs(regs,[]);
hw.write('DIGGnx|DIGGnx|DIGGnx|DIGGnx|DIGGnx|DIGGnx|DIGGdx2|DIGGdx3|DIGGdx5|DIGGny|DIGGny|DIGGny|DIGGny|DIGGny|DIGGny|DIGGdy2|DIGGdy3|DIGGdy5|');
d=hw.getFrame();
e=Calibration.aux.evalProjectiveDisotrtion(d.i);
end