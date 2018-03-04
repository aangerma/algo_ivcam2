function score=runCalibStream(outputFolder,doInit,fprintff,verbose)
% load dbg

%% ::caliration configuration
calibParams.version = 001.001;
calibParams.errTol.delayF = 5.0;
calibParams.errTol.delayS = 5.0;
calibParams.errTol.geometric = 1.0;
calibParams.errTol.validation = 2.0;

if(~exist('verbose','var'))
    verbose=true;
end

%% ::Init fw
fprintff('Loading Firmware...',false);
initConfigCalib = fullfile(fileparts(mfilename('fullpath')),'initScript');
fw = Pipe.loadFirmware(initConfigCalib);
hw=HWinterface(fw);
if(doInit)
    fprintff('init...',false);
    tfn = [tempname '.txt'];
    fw.get();%run autogen
    fw.genMWDcmd([],tfn);
    
    hw.runScript(tfn);
end
fprintff('Done',true);

calibfn = fullfile(outputFolder,filesep,'calib.csv');
undsitLutFn = fullfile(outputFolder,filesep,'FRMWundistModel.bin32');
%% ::calibrate delays::
fprintff('Depth and IR delay calibration...',true);
[delayRegs,delayErr] = Calibration.runCalibChDelays(hw, verbose);
fw.setRegs(delayRegs,calibfn);

if(all(delayErr<[calibParams.errTol.delayS calibParams.errTol.delayF]))
    fprintff('SUCCESS(err fast:%g, err slow:%g)',delayErr,true);
else
    fprintff('FAILED(err fast:%g, err slow:%g)',delayErr,true);
    score = 0;
    return;
end


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
%% ::calibrate DOD curve::

fprintff('FOV, System Delay, Zenith and Distortion calibration...',true);
[dodregs,luts.FRMW.undistModel,geomErr] = Calibration.aux.runDODCalib(hw,verbose);
fw.setRegs(dodregs,calibfn);
fw.setLut(luts);


if(geomErr<calibParams.errTol.geometric)
    fprintff('SUCCESS(err :%g)',geomErr,true);
else
    fprintff('FAILED(err :%g)',geomErr,true);
    score = 0;
    return;
end

fprintff('Validating...',true);
%validate
tfn = [tempname '.txt'];
fw.get();%run autogen
fw.genMWDcmd([],tfn);
hw.runScript(tfn);
[~,~,geomErr] = Calibration.aux.runDODCalib(hw,verbose);
%dodregs2 should be equal to dodregs

%write version
verValue = uint32(floor(calibParams.version)*256+floor(mod(calibParams.version,1)*1000+1e-3));
verRegs.DIGG.spare=[verValue zeros(1,7,'uint32')];
fw.setRegs(verRegs,calibfn);


fw.writeUpdated(calibfn);
io.writeBin(undsitLutFn,undistModel);

fw.genMWDcmd('EXTLcbufMemBufSz|EXTLconLoc|EXTLdsm',fullfile(outputFolder,filesep,'algoInit.csv'));

fw.genMWDcmd([],fullfile(outputFolder,filesep,'algoCalib.csv'));


VAL_BEST = .5;
VAL_WROST= 4;
score = round((VAL_WROST-validErr)/(VAL_WROST-VAL_BEST)*4+1);

fprintff('Done',true);



%% merge all scores outputs
scores = struct();
f = fieldnames(resChDelays);
for i = 1:length(f)
    scores.(f{i}) = resChDelays.(f{i});
end

f = fieldnames(resDODParams);
for i = 1:length(f)
    scores.(f{i}) = resDODParams.(f{i});
end

scores.errGeomVal = errGeomVal;

%% define score thresholds, load from xml
scoresThresholds = {...
    {'errFast', 2.5, 5.0, 'fast delay score (pixels)'},...
    {'errSlow', 2.5, 5.0, 'slow delay score (pixels)'},...
    {'errGeom', 2.0, 5.0, 'DOD optimization score (mm)'}, ...
    {'errGeomVal', 2.0, 5.0, 'DOD validation score (mm)'}, ...
    };

fprintff('Scores:\n');

totalCalibStr = 'pass';

for i=1:length(scoresThresholds)
    sth = scoresThresholds{i};
    s = scores.(sth{1});
    if (s > sth{3})
        resStr = 'fail';
        totalCalibStr = 'fail';
    elseif (s > sth{2})
        resStr = 'pass (bad)';
    else
        resStr = 'pass';
    end
        
    fprintff(' - %s (%2.2f)): %s\n', sth{4}, s, resStr);
end


fprintff(' Algo calibration summary: %s\n', totalCalibStr);



end
