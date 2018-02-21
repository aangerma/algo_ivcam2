function score=runCalibStream(hw, configFldr,outputFolder,fprintff,verbose)
if(~exist('verbose','var'))
    verbose=true;
end
%fprintff = @(varargin) verbose&&fprintf(varargin{:});

%fprintff('Loading Firmware...',false);
%fw=Pipe.loadFirmware(configFldr);
%fprintff('Done',true);
%fprintff('Connecting HW interface...',false);
% hw=HWinterface(fw);
%fprintff('Done',true);

%% ::Set some basic configuration:: %%
% Makes sure we know the current configuration. Also set a better DSM calib and CBUF mode. 
fprintff('Setting default configuration. This might take two or three minutes...');
preAlgoScript = fullfile(fileparts(mfilename('fullpath')),'IVCAM20Scripts','algoConfigInitial.txt');
%preAlgoScript = fullfile(fileparts(mfilename('fullpath')),'IVCAM20Scripts','preAlgo.txt');
%hw.runScript(preAlgoScript);
fprintff('Done\n');


%% ::calibrate delays::
fprintff('Depth and IR delay calibration...');
resChDelays = Calibration.runCalibChDelays(hw, verbose);
fnChDelays = fullfile(outputFolder, 'pi_conloc_delays.txt');
Calibration.aux.writeChannelDelaysMWD(fnChDelays, resChDelays.delayFast, resChDelays.delaySlow, true);
fprintff('Done');
fprintff('[*] Delays Score:\n - errFast = %2.2fmm\n - errSlow=%2.2fmm\n',resChDelays.errFast,resChDelays.errSlow);

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

fprintff('FOV, System Delay, Zenith and Distortion calibration...\n');
resDODParams = Calibration.aux.runDODCalib(hw,verbose);
fnDODParams = fullfile(outputFolder, 'dod_params.txt');
Calibration.aux.writeDODParamsMWD(fnDODParams, resDODParams, true);
fprintff('Done');
fprintff('[*] DOD Score:\n - eAlex = %2.2fmm\n - eFit = %2.2fmm\n - eDistortion = %2.2fmm\n',resDODParams.score,resDODParams.eFit,resDODParams.eDist);

fnVer = fullfile(outputFolder, 'ver.txt');
Calibration.aux.writeVersionReg(fnVer, 1, true);

fnAlgoCalib = fullfile(outputFolder, 'Algo_Pipe_Calibration_CalibData_Ver_01_01.txt');
system(['copy /y /b ' fnVer '+' fnChDelays '+' fnDODParams ' ' fnAlgoCalib]);

%% write calib files in full firmware formate
Calibration.aux.writeChannelDelaysMWD(fnChDelays, resChDelays.delayFast, resChDelays.delaySlow, false);
Calibration.aux.writeDODParamsMWD(fnDODParams, resDODParams, false);

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

%% define score thresholds, load from xml
scoresThresholds = {...
    {'errFast', 2.5, 5.0, 'fast delay score (pixels)'},...
    {'errSlow', 2.5, 5.0, 'slow delay score (pixels)'},...
    {'score', 2.0, 5.0, 'DOD score (mm)'}, ...
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
        resStr = 'bad';
    else
        resStr = 'pass';
    end
        
    fprintff(' - %s (%2.2f)): %s\n', sth{1}, s, resStr);
end

fprintff(' Algo calibration summary: %s\n', totalCalibStr);

end
