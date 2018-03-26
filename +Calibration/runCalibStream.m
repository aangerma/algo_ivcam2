function [score,dbg]=runCalibStream(outputFolder,doInit,fprintff,verbose,calibVersion)
t=tic;

%% ::caliration configuration
calibParams.errRange.delayF =  [0.5 3.0];
calibParams.errRange.delayS =  [0.5 3.0];
calibParams.errRange.geomErr = [0.5 3.0];
calibParams.errRange.geomErrVal =  [0.5 3.0];
calibParams.errRange.gammaErr =  [1 5000];
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
fprintff('Done(%d)\n',round(toc(t)));

fprintff('Loading HW interface...');
hw=HWinterface(fw);
fprintff('Done(%d)\n',round(toc(t)));
[regs,luts]=fw.get();%run autogen

hw.runPresetScript('systemConfig');
if(doInit)  
    fnAlgoInitMWD  =  fullfile(internalFolder,filesep,'algoInit.txt');
    fw.genMWDcmd([],fnAlgoInitMWD);
    fprintff('init...');
    hw.runScript(fnAlgoInitMWD);
    hw.shadowUpdate();
    fprintff('Done(%d)\n',round(toc(t)));
end
hw.runPresetScript('startStream');

setLaserProjectionUniformity(hw,true);
%% ::calibrate delays::
showImageRequestDialog(hw,1,diag([.8 .8 1]));
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


regs.DEST.depthAsRange=true;regs.DIGG.sphericalEn=true;
hw.setReg('JFILinvBypass',true);
hw.setReg('DESTdepthAsRange',true);
hw.setReg('DIGGsphericalEn',true);
hw.shadowUpdate();

d(1)=showImageRequestDialog(hw,1,diag([.7 .7 1]));
d(2)=showImageRequestDialog(hw,1,diag([.6 .6 1]));
d(3)=showImageRequestDialog(hw,1,diag([.5 .5 1]));
d(4)=showImageRequestDialog(hw,1,[.5 0 .1;0 .5 0; 0.2 0 1]);
d(5)=showImageRequestDialog(hw,1,[.5 0 -.1;0 .5 0; -0.2 0 1]);
d(6)=showImageRequestDialog(hw,2,diag([2 2 1]));
dbg.d=d;
dbg.regs=regs;
dbg.luts=luts;

% dodluts=struct;

[dodregs,results.geomErr] = Calibration.aux.calibDFZ(d(1:3),regs,verbose);
hw.setReg('DESTdepthAsRange',false);
hw.setReg('DIGGsphericalEn',false);
hw.shadowUpdate();

fw.setRegs(dodregs,fnCalib);
% fw.setLut(dodluts);
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

fnAlgoTmpMWD =  fullfile(internalFolder,filesep,'algoValidCalib.txt');
[regs,luts]=fw.get();%run autogen
fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
hw.runScript(fnAlgoTmpMWD);
hw.shadowUpdate();
d=hw.getFrame(30);
[~,results.geomErrVal] = Calibration.aux.calibDFZ(d,regs,verbose,true);

%dodregs2 should be equal to dodregs


if(inrange(results.geomErrVal,calibParams.errRange.geomErrVal))
    fprintff('[v] geom valid passed[e=%g]\n',results.geomErrVal);
else
    fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);

end

dbg.validImg = d;
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
save(fullfile(internalFolder,'imData.mat'),'dbg');
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

hw.runPresetScript('stopStream');


end

function setLaserProjectionUniformity(hw,uniformProjection)
if(uniformProjection)
    hw.cmd('Iwb e2 03 01 93');
else
    hw.cmd('Iwb e2 03 01 13');
end

end


function raw=showImageRequestDialog(hw,figNum,tformData)
persistent figImgs;
figTitle = 'Please align image board to overlay';
if(isempty(figImgs))
    bd = fullfile(fileparts(mfilename('fullpath')),filesep,'targets',filesep);
    figImgs{1} = imread([bd 'calibrationChart.png']);
    figImgs{2} = imread([bd 'fineCheckerboardA3.png']);
end

f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
a=axes('parent',f);
maximizeFig(f);
I = mean(figImgs{figNum},3);
%%

move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1 -1 1];

It= imwarp(I, projective2d(move2Ncoords*tformData'),'bicubic','fill',0,'OutputView',imref2d([480 640],[-1 1],[-1 1]));
It = uint8(It.*permute([0 1 0],[3 1 2]));

%%
while(ishandle(f) && get(f,'userdata')==0)
    
    raw=hw.getFrame();
    image(uint8(repmat(raw.i*.8,1,1,3)+It*.25));
    axis(a,'image');
    axis(a,'off');
    title(figTitle);
    colormap(gray(256));
    drawnow;
end
close(f);

raw=hw.getFrame(30);



end