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

%% ::Set some basic configuration:: %%
% Makes sure we know the current configuration. Also set a better DSM calib and CBUF mode. 
fprintff('Setting default configuration. This might take two or three minutes...',false);
preAlgoScript = fullfile(fileparts(mfilename('fullpath')),'IVCAM20Scripts','algoConfigInitial.txt');
hw.runScript(preAlgoScript);
fprintff('Done\n',true);


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

fprintff('FOV, System Delay, Zenith and Distortion calibration...\n',false);
resDODParams = Calibration.aux.runDODCalib(hw,verbose);
fnDODParams = fullfile(outputFolder, 'dod_params.txt');
Calibration.aux.writeDODParamsMWD(fnDODParams, resDODParams);
fprintff('Done',true);
fprintff('[*] DOD Score: eAlex=%2.2fmm. eFit=%2.2fmm. eDistortion=%2.2fmm.  \n',resDODParams.score,resDODParams.eFit,resDODParams.eDist);


end
