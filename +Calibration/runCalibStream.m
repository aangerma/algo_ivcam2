function score=runCalibStream(outputFolder,doInit,fprintff,verbose)
% load dbg

%% ::caliration configuration
calibParams.version = 001.001;
calibParams.errTol.delayF = 5.0;
calibParams.errTol.delayS = 5.0;
calibParams.errTol.geometric = 2.0;
calibParams.errTol.validation = 2.0;

if(~exist('verbose','var'))
    verbose=true;
end
%% :: file names
fnCalib     = fullfile(outputFolder,filesep,'calib.csv');
fnUndsitLut = fullfile(outputFolder,filesep,'FRMWundistModel.bin32');

fnAlgoInitMWD  = fullfile(outputFolder,filesep,'algoInit.txt');
fnCalibMWD = fullfile(outputFolder,filesep,'algoCalib.txt');
%% ::Init fw
fprintff('Loading Firmware...',false);
initConfigCalib = fullfile(fileparts(mfilename('fullpath')),'initScript');
fw = Pipe.loadFirmware(initConfigCalib);
hw=HWinterface(fw);

fw.get();%run autogen
fw.genMWDcmd([],fnAlgoInitMWD);
if(doInit)    
    fprintff('init...',false);
    hw.runScript(fnAlgoInitMWD);
    hw.shadowUpdate();
end
fprintff('Done',true);


%% ::calibrate delays::
% fprintff('Depth and IR delay calibration...',true);
% [delayRegs,delayErr] = Calibration.runCalibChDelays(hw, verbose);
% fw.setRegs(delayRegs,fnCalib);
% 
% if(all(delayErr<[calibParams.errTol.delayS calibParams.errTol.delayF]))
%     fprintff('SUCCESS(err fast:%g, err slow:%g)',delayErr,true);
% else
%     fprintff('FAILED(err fast:%g, err slow:%g)',delayErr,true);
%     score = 0;
%     return;
% end


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

% Make 100% sure the DOD calibration initialization is correct:
DODRegsNames = 'DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|FRMWgaurdBandH|FRMWgaurdBandV|FRMWlaserangleH|FRMWlaserangleV|FRMWxfov|FRMWyfov|DIGGundistModel|FRMWundistModel';
fnAlgoDODInitMWD  = fullfile(outputFolder,filesep,'dodInit.txt');
fw.get();%run autogen
fw.genMWDcmd(DODRegsNames,fnAlgoDODInitMWD);
if(doInit)    
    fprintff('init...',false);
    hw.runScript(fnAlgoDODInitMWD);
    hw.shadowUpdate();
end



fprintff('FOV, System Delay, Zenith and Distortion calibration...',true);
nIters = 5;
hw.runCommand('mwd a00e1894 a00e1898 00000000') % Confidence thresh to 0
hw.runCommand('mwd a00d01f4 a00d01f8 00000fff') % Depth Shadow update
[dodregs,luts.FRMW.undistModel,geomErr] = Calibration.aux.runDODCalib(hw,verbose,nIters);
fw.setRegs(dodregs,fnCalib);
fw.setLut(luts);


if(geomErr<calibParams.errTol.geometric)
    fprintff('DOD Training SUCCESS(err: %g)\n',geomErr);
else
    fprintff('DOD Training FAILED(err: %g)\n',geomErr);
    score = 0;
    return;
end

fprintff('Validating...\n',true);
%validate
fnAlgoTmpMWD = fullfile(outputFolder,filesep,'DODresult.txt');
fw.get();%run autogen
fw.genMWDcmd(DODRegsNames,fnAlgoTmpMWD);
hw.runScript(fnAlgoTmpMWD);
hw.runCommand('mwd a00d01f4 a00d01f8 00000fff') % Depth Shadow update
[~,~,geomErrVal] = Calibration.aux.runDODCalib(hw,verbose,0);
%dodregs2 should be equal to dodregs
if(geomErrVal<calibParams.errTol.geometric)
    fprintff('DOD Validation SUCCESS(err: %g)\n',geomErrVal);
else
    fprintff('DOD Validation FAILED(err: %g)\n',geomErrVal);
    score = 0;
    return;
end


%write version
verValue = uint32(floor(calibParams.version)*256+floor(mod(calibParams.version,1)*1000+1e-3));
verRegs.DIGG.spare=[verValue zeros(1,7,'uint32')];
fw.setRegs(verRegs,fnCalib);


fw.writeUpdated(fnCalib);
io.writeBin(fnUndsitLut,undistModel);



fw.genMWDcmd([],fnCalibMWD);


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
