function score=runCalibStream(outputFolder,doInit,fprintff,verbose,calibVersion)
t=tic;

%% ::caliration configuration
calibParams.version = 001.001;
calibParams.errRange.delayF = [2.5 5.0];
calibParams.errRange.delayS = [2.5 5.0];
calibParams.errRange.geomErr = [2.0 5.0];
calibParams.errRange.geomErrVal = [2.0 5.0];
calibParams.errRange.gammaErr = [0 5000];

inrange =@(x,r)  x<r(2);
results = struct;


if(~exist('verbose','var'))
    verbose=true;
end
%% :: file names
internalFolder = fullfile(outputFolder,filesep,'AlgoInternal');
fnCalib     = fullfile(internalFolder,filesep,'calib.csv');
fnUndsitLut = fullfile(internalFolder,filesep,'FRMWundistModel.bin32');
initFldr = fullfile(fileparts(mfilename('fullpath')),'initScript');
copyfile(fullfile(initFldr,filesep,'*.csv'),internalFolder)

mkdirSafe(outputFolder);
mkdirSafe(internalFolder);


%% ::Init fw
fprintff('Loading Firmware...');

fw = Pipe.loadFirmware(internalFolder);
hw=HWinterface(fw);

[regs,luts]=fw.get();%run autogen

if(doInit)  
    fnAlgoInitMWD  =  fullfile(internalFolder,filesep,'algoInit.txt');
    fw.genMWDcmd([],fnAlgoInitMWD);
    fprintff('init...');
    hw.runScript(fnAlgoInitMWD);
    hw.shadowUpdate();
end
fprintff('Done(%d)\n',round(toc(t)));


%% ::calibrate delays::
fprintff('Depth and IR delay calibration...\n');
[delayRegs,results.delayS,results.delayF] = Calibration.runCalibChDelays(hw,  verbose);

if(inrange(results.delayS,calibParams.errRange.delayS))
    fprintff('[v] slow calib passed[e=%g]\n',results.delayS);
else
    fprintff('[x] slow calib failed[e=%g]\n',results.delayS);
    score = 0;
    return;
end

if(inrange(results.delayF,calibParams.errRange.delayF))
    fprintff('[v] fast calib passed[e=%g]\n',results.delayF);
else
    fprintff('[x] fast calib failed[e=%g]\n',results.delayF);
    score = 0;
    return;
end
fprintff('Done(%d)\n',round(toc(t)));

fw.setRegs(delayRegs,fnCalib);


%% ::calibrate DOD curve::

% Make 100% sure the DOD calibration initialization is correct:
% % % DODRegsNames = 'DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|FRMWgaurdBandH|FRMWgaurdBandV|FRMWlaserangleH|FRMWlaserangleV|FRMWxfov|FRMWyfov|DIGGundistModel|FRMWundistModel';
% % % fnAlgoDODInitMWD  = fullfile(outputFolder,filesep,'dodInit.txt');
% % % fw.get();%run autogen
% % % fw.genMWDcmd(DODRegsNames,fnAlgoDODInitMWD);
% % % if(doInit)    
% % %     fprintff('init...',false);
% % %     hw.runScript(fnAlgoDODInitMWD);
% % %     hw.shadowUpdate();
% % % end


fprintff('FOV, System Delay, Zenith and Distortion calibration...\n');

hw.setReg('DESTdepthAsRange',true);
hw.setReg('DIGGsphericalEn',true);
[dodregs,luts.FRMW.undistModel,results.geomErr] = Calibration.aux.calibDFZ(hw.getFrame(30),regs,luts,verbose);
hw.setReg('DESTdepthAsRange',true);
hw.setReg('DIGGsphericalEn',true);



fw.setRegs(dodregs,fnCalib);
fw.setLut(luts);
% [regs,luts]=fw.get();%run autogen


if(inrange(results.geomErr,calibParams.errRange.geomErr))
    fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
else
    fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
    score = 0;
    return;
end
fprintff('Done(%d)\n',round(toc(t)));


fprintff('Validating...\n');
%validate
regsDODnames='DESTp2axa|DESTp2axb|DESTp2aya|DESTp2ayb|DESTtxFRQpd|DIGGang2Xfactor|DIGGang2Yfactor|DIGGangXfactor|DIGGangYfactor|DIGGdx2|DIGGdx3|DIGGdx5|DIGGdy2|DIGGdy3|DIGGdy5|DIGGnx|DIGGny|DIGGundist';

fnAlgoTmpMWD =  fullfile(internalFolder,filesep,'algoValidCalib.txt');
[regs,luts]=fw.get();%run autogen
fw.genMWDcmd(regsDODnames,fnAlgoTmpMWD);
hw.runScript(fnAlgoTmpMWD);
hw.shadowUpdate();
results.geomErrVal = calcGeometricDistortion(hw.getFrame(),regs,verbose);
%dodregs2 should be equal to dodregs


if(inrange(results.geomErrVal,calibParams.errRange.geomErrVal))
    fprintff('[v] geom valid passed[e=%g]\n',results.geomErrVal);
else
    fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);
    score = 0;
    return;
end


% % % %% ::calibrate gamma scale shift and lut::
% % % [gammaregs,results.gammaErr] = Calibration.aux.runGammaCalib(hw,verbose);
% % % fw.setRegs(gammaregs,fnCalib);
% % % if(inrange(results.gammaErr,calibParams.errRange.gammaErr))
% % %     fprintff('[v] gamma passed[e=%g]\n',results.gammaErr);
% % % else
% % %     fprintff('[x] gamma failed[e=%g]\n',results.gammaErr);
% % %     score = 0;
% % %     return;
% % % end

%% write version
if(exist('calibVersion','var'))
verhex=(cellfun(@(x) dec2hex(uint8(str2double(x)),2),strsplit(calibVersion,'.'),'uni',0));
verValue = uint32(hex2dec([verhex{:}]));
verRegs.DIGG.spare=[verValue zeros(1,7,'uint32')];
fw.setRegs(verRegs,fnCalib);
end

fw.writeUpdated(fnCalib);
io.writeBin(fnUndsitLut,luts.FRMW.undistModel);

fprintff('Done(%d)\n',round(toc(t)));


%% merge all scores outputs

f = fieldnames(results);
scores=zeros(length(f),1);
for i = 1:length(f)
    scores(i)=100-round(min(1,max(0,(results.(f{i})-calibParams.errRange.(f{i})(1))/diff(calibParams.errRange.(f{i}))))*99+1);
   
    

end
score = min(scores);


if(verbose)
    for i = 1:length(f)
        s04=floor((scores(i)-1)/100*5);
        asciibar = sprintf('|%s#%s|',repmat('-',1,s04),repmat('-',1,4-s04));
        ll=fprintff('% 10s: %s %g\n',f{i},asciibar,results.(f{i}));
    end
    fprintff('%s\n',repmat('-',1,ll));
    s04=floor((score-1)/100*5);
    asciibar = sprintf('|%s#%s|',repmat('-',1,s04),repmat('-',1,4-s04));
    fprintff('% 10s: %s\n','score',asciibar);
    
end




end

