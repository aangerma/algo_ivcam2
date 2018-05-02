function [score,dbg]=runCalibStream(params, fprintff)
t=tic;
if(ischar(params))
    params=xml2structWrapper(params);
    params.version = num2str(params.version);%gui consistency
end
if(~exist('fprintff','var'))
    fprintff=@(varargin) fprintf(varargin{:});
end
verbose = params.verbose;
%% ::caliration configuration
calibParams = xml2structWrapper(sprintf('%s\\calibParams\\calibParams.xml',fileparts(mfilename('fullpath'))));



results = struct;

dbg.runStarted=datestr(now);

%% :: file names
params.internalFolder = fullfile(params.outputFolder,filesep,'AlgoInternal');

struct2xmlWrapper(params,sprintf('%s\\calibrationInputParams.xml',params.internalFolder));

mkdirSafe(params.outputFolder);
mkdirSafe(params.internalFolder);


fnCalib     = fullfile(params.internalFolder,filesep,'calib.csv');
fnUndsitLut = fullfile(params.internalFolder,filesep,'FRMWundistModel.bin32');
initFldr = fullfile(fileparts(mfilename('fullpath')),'initScript');
copyfile(fullfile(initFldr,filesep,'*.csv'), params.internalFolder)

%% ::Init fw
fprintff('Loading Firmware...');
fw = Pipe.loadFirmware(params.internalFolder);
fprintff('Done(%d)\n',round(toc(t)));

fprintff('Loading HW interface...');
hw=HWinterface(fw);
fprintff('Done(%d)\n',round(toc(t)));
[regs,luts]=fw.get();%run autogen

% hw.runPresetScript('systemConfig');
fprintff('init...');
if(params.init)  
    fnAlgoInitMWD  =  fullfile(params.internalFolder,filesep,'algoInit.txt');
    fw.genMWDcmd([],fnAlgoInitMWD);
   
    hw.runScript(fnAlgoInitMWD);
    hw.shadowUpdate();
    fprintff('Done(%d)\n',round(toc(t)));
else
    fprintff('skipped\n');
end
 
% hw.runPresetScript('startStream');


%% ::calibrate delays::
fprintff('Depth and IR delay calibration...\n');




if(params.dataDelay)
    Calibration.dataDelay.setAbsDelay(hw,calibParams.dataDelay.slowDelayInitVal,false);
    dbg.preImg=showImageRequestDialog(hw,1,diag([.8 .8 1]));
    [delayRegs,okZ,okIR]=Calibration.dataDelay.calibrate(hw,calibParams.dataDelay,verbose);
    results.delayS=(1-okIR);
    results.delayF=(1-okZ);
    if(okIR)
        fprintff('[v] ir calib passed[e=%g]\n',results.delayS);
    else
        fprintff('[x] ir calib failed[e=%g]\n',results.delayS);
        score = 0;
        return;
    end
    
    if(okZ)
        fprintff('[v] depth calib passed[e=%g]\n',results.delayF);
    else
        fprintff('[x] depth calib failed[e=%g]\n',results.delayF);
        score = 0;
        return;
    end
    fprintff('Done(%d)\n',round(toc(t)));
    fw.setRegs(delayRegs,fnCalib);
    
else
    results.delayS=inf;
    results.delayF=inf;
    fprintff('skipped\n');
end

%% ::gamma::
params.gamma = false;
fprintff('gamma...\n');
if (params.gamma)
    
%     [gammaregs,results.gammaErr] = Calibration.aux.runGammaCalib(hw,.verbose);
%     
%     if(results.gammaErr,calibParams.errRange.gammaErr(2))
%         fprintff('[v] gamma passed[e=%g]\n',results.gammaErr);
%     else
%         fprintff('[x] gamma failed[e=%g]\n',results.gammaErr);
%         score = 0;
%         return;
%     end
%     fw.setRegs(gammaregs,fnCalib);
    results.gammaErr=0;
else
    results.gammaErr=inf;
    fprintff('skipped\n');
end
%% ::RX Delay::
rxregs = Calibration.aux.rxDelay2regs(params.rx,[]); %pass gamma regs when available.
fw.setRegs(rxregs,fnCalib);
%% ::DFZ::

fprintff('FOV, System Delay, Zenith and Distortion calibration...\n');
if(params.DFZ)
    setLaserProjectionUniformity(hw,true);
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
    if(results.geomErr<calibParams.errRange.geomErr(2))
        fprintff('[v] geom calib passed[e=%g]\n',results.geomErr);
    else
        fprintff('[x] geom calib failed[e=%g]\n',results.geomErr);
        score = 0;
        return;
    end
    setLaserProjectionUniformity(hw,false);
    fprintff('Done(%d)\n',round(toc(t)));
else
    fprintff('skipped\n');
    results.geomErr=inf;
end


%% ::validation::





fprintff('Validating...\n');
%validate
if(params.validation)
    fnAlgoTmpMWD =  fullfile(params.internalFolder,filesep,'algoValidCalib.txt');
    [regs,luts]=fw.get();%run autogen
    fw.genMWDcmd('DEST|DIGG',fnAlgoTmpMWD);
    hw.runScript(fnAlgoTmpMWD);
    hw.shadowUpdate();
    d=showImageRequestDialog(hw,1,diag([.7 .7 1]));
    dbg.validImg = d;
    [~,results.geomErrVal] = Calibration.aux.calibDFZ(d,regs,verbose,true);
    if(results.geomErrVal<calibParams.errRange.geomErrVal(2))
        fprintff('[v] geom valid passed[e=%g]\n',results.geomErrVal);
    else
        fprintff('[x] geom valid failed[e=%g]\n',results.geomErrVal);
        
    end
else
    fprintff('skipped\n');
    results.geomErrVal=inf;
end





%% write version+intrinsics
verhex=(cellfun(@(x) dec2hex(uint8(str2double(x)),2),strsplit(params.version,'.'),'uni',0));
verValue = uint32(hex2dec([verhex{:}]));
verRegs.DIGG.spare=zeros(1,8,'uint32');
verRegs.DIGG.spare(1)=verValue;
intregs.DIGG.spare(2)=typecast(single(dodregs.FRMW.xfov),'uint32');
intregs.DIGG.spare(3)=typecast(single(dodregs.FRMW.yfov),'uint32');
intregs.DIGG.spare(4)=typecast(single(dodregs.FRMW.laserangleH),'uint32');
intregs.DIGG.spare(5)=typecast(single(dodregs.FRMW.laserangleV),'uint32');
fw.setRegs(intregs,fnCalib);
fw.setRegs(verRegs,fnCalib);
fw.writeUpdated(fnCalib);

io.writeBin(fnUndsitLut,luts.FRMW.undistModel);
save(fullfile(params.internalFolder,'imData.mat'),'dbg');
fprintff('Done(%d)\n',round(toc(t)));

fw.writeFirmwareFiles(params.outputFolder);







%% merge all scores outputs

f = fieldnames(results);
scores=zeros(length(f),1);
for i = 1:length(f)
    scores(i)=100-round(min(1,max(0,(results.(f{i})-calibParams.errRange.(f{i})(1))/diff(calibParams.errRange.(f{i}))))*99);
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
    fprintff('% 10s: %s %g\n','score',asciibar,score);
    
end


fprintff('[!] calibration ended - ');
if(score==0)
    fprintff('failed');
elseif(score<calibParams.passScore)
    fprintff('quality failed');
else
    fprintff('pass');
end
    

if(params.burnCalibrationToDevice)
    fprintff('Burning results to device...');
    if(score>=calibParams.passScore)
        hw.burn2device();
        fprintff('Done(%d)\n',round(toc(t)));
    else
        fprintff('skiped, score too low(%d)\n',score);
    end
end

end

function setLaserProjectionUniformity(hw,uniformProjection)
if(uniformProjection) %non-safe
%     [~,val]=hw.cmd('irb e2 0a 01');
%     newval=uint8(round((double(val(1))/63*150+150)/300*255));
%     hw.cmd(sprintf('iwb e2 08 01 %02x',newval));
     hw.cmd('iwb e2 08 01 ff');
     hw.cmd('iwb e2 03 01 13');
else
    hw.cmd('iwb e2 03 01 93');
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

move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];

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

