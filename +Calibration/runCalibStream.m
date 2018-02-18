function score=runCalibStream(hw, configFldr,outputFolder,fprintff,verbose)
if(~exist('verbose','var'))
    verbose=true;
end
% fprintff = @(varargin) verbose&&fprintf(varargin{:});

%fprintff('Loading Firmware...',false);
%fw=Pipe.loadFirmware(configFldr);
%fprintff('Done',true);
%fprintff('Connecting HW interface...',false);
% hw=HWinterface(fw);
%fprintff('Done',true);

%% ::calibrate delays::
fprintff('Depth and IR delay calibration...',false);
resChDelays = Calibration.runCalibChDelays(hw, verbose);
fnChDelays = fullfile(outputFolder, 'pi_conloc_delays.txt');
Calibration.aux.writeChannelDelaysMWD(fnChDelays, resChDelays.delayFast, resChDelays.delaySlow);
fprintff('Done',true);

%fprintff('XY delay calibration...',false);
%fprintff('Done',true);

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

return;

fprintff('DOD init...\n',false);
% Update some regs for the optimization
luts.FRMW.undistModel=zeros(2048,1,'uint32');
initRegs.JFIL.bypass = false;
initRegs.DIGG.undistBypass=false;
initRegs.DEST.txFRQpd=single([5000 5000 5000]);
initRegs.JFIL.invConfThr = uint8(0); % return to default at the end
fw.setRegs(initRegs,configFldr);
fw.setLut(luts);
[regs,luts] = fw.get();
% hw.write('FRMWundistModel|JFILbypass|DIGGundistBypass|DESTtxFRQpd|JFILinvConfThr')

nFrames = 30;
% [~,avgD] = readFrames(hw,nFrames); % Read an average of 30 frames
[dodRegs,dodLuts,score] = Calibration.aux.runDODCalib(avgD,regs,luts,verbose);
fprintff('Done',true);

fprintff('[*] DOD Score: %g',score,true);
fprintff('Saving DOD calibrated configuration...',false);
calibfn = fullfile(outputFolder,filesep,'calib.csv');
undistfn=fullfile(outputFolder,filesep,'FRMWundistModel.bin32');
io.writeBin(undistfn,dodLuts.FRMW.undistModel)
fw.setRegs(dodRegs,calibfn);
fw.setLuts(dodLuts);
fw.writeUpdated(calibfn)
fprintff('Done',true);
fw.genMWDcmd([],fullfile(outputFolder,filesep,'algoConfig.txt'));
end

function [stream,avgD] = readFrames(hw,N)
for i = 1:N
   stream(i) = hw.getFrame(); 
end
collapseM = @(x) mean(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),3);
avgD.z=collapseM('z');
avgD.i=collapseM('i');
avgD.c=collapseM('c');

end