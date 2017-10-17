function POC4analyzer(mirrorFlavor,inoutFolder,nFrameSkip,verbose)
% matlab 2015a !!!
% deploytool
% library compiler
% .NET assembly
% add POC4analyzer.m & runPipe.m
% library name: POC4analyzer
% class name : POC4
% files req... : add 'tables' dir
% finish

mirrorFlavorTypes = {'A','B'};


if(nargin==0)
    buildGui(mirrorFlavorTypes);
else
    if(~exist('verbose','var'))
        verbose = 0;
    end
    
    %check for valid mirror type
    if(isempty(find(strcmp(mirrorFlavorTypes,mirrorFlavor), 1)))
        error('mirror flavor should be one of: %s',cell2str(mirrorFlavorTypes,',') )
    end
    
    
    run(mirrorFlavor,inoutFolder,nFrameSkip,verbose);
end


end

function buildGui(mirrorFlavorTypes)
%%

W=600;
H=150;

DEF_FOLDER = 'd:\Ohad\data\lidar\EXP\20170424\7014MB4104DF\240417\POC4\8MHz\Chess_Board\';
% DEF_CONFIG = '\\invcam322\Ohad\data\lidar\EXP\20170109\01\config.csv';
DEF_FLAVOR = 'B';


h.f = figure('name','X0  analyzer','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);
lh=22;
currH = H-1.5*lh;

%input dir
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','data folder','horizontalalignment','left','parent',h.f);
h.dataFolder = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',DEF_FOLDER,'horizontalalignment','left','parent',h.f);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',@callbackChooseDir);
%
% %config file
% currH = currH-1.5*lh;
% uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','config file','horizontalalignment','left','parent',h.f);
% h.configFn = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',DEF_CONFIG,'horizontalalignment','left','parent',h.f);
% uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',@callbackChooseFile);

%mirror flavor
currH = currH-1.5*lh;
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','Mirror flavor','horizontalalignment','left','parent',h.f);
h.mirrorFlavor = uicontrol('style','popup','units','pixels','position',[120 currH 2*lh lh],'String',mirrorFlavorTypes,'value',find(strcmp(mirrorFlavorTypes,DEF_FLAVOR),1),'parent',h.f);

uicontrol('style','text','units','pixels','position',[210 currH 120 lh],'String','nFrameSkip','horizontalalignment','left','parent',h.f);
h.nFrameSkip = uicontrol('style','edit','units','pixels','position',[280 currH 2*lh lh],'String','0','value',find(strcmp(mirrorFlavorTypes,DEF_FLAVOR),1),'parent',h.f);


% %run pipe
% currH = currH-1.5*lh;
% uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','run Pipe','horizontalalignment','left','parent',h.f);
% h.runPipe = uicontrol('style','checkbox','units','pixels','position',[120 currH 2*lh lh],'value',0,'parent',h.f);
%
%verbose
currH = currH-1.5*lh;
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','verbose','horizontalalignment','left','parent',h.f);
h.verbose = uicontrol('style','checkbox','units','pixels','position',[120 currH 2*lh lh],'value',0,'parent',h.f);

%generate IVS
uicontrol('style','pushbutton','units','pixels','position',[10 10 W-20 lh],'String','generate IVS','parent',h.f,'callback',@callback_run);

guidata(h.f,h);

end

function callbackChooseDir(varargin)
h=guidata(varargin{1});
d = uigetdir(h.dataFolder.String);
if(~isa(d,'numeric'))
    h.dataFolder.String = d;
end
end

% function callbackChooseFile(varargin)
% h=guidata(varargin{1});
% [FileName,PathName] = uigetfile(h.configFn.String);
% if(~isa(FileName,'numeric'))
%     h.configFn.String = [PathName FileName];
% end
% end


function callback_run(varargin)
h=guidata(varargin{1});

mirrorFlavor = h.mirrorFlavor.String{h.mirrorFlavor.Value};
inoutFolder = h.dataFolder.String;
verbose = h.verbose.Value;
nFrameSkip = str2double(h.nFrameSkip.String);
run(mirrorFlavor,inoutFolder,nFrameSkip,verbose);
end

function run(mirrorFlavor,inoutFolder,nFrameSkip,verbose)



% height=single(str2double(h.yres.String));
% width=single(str2double(h.xres.String));
% txFreq = single(iff(h.txfreq.Value,1,.5,0.250));




% propDist=single(str2double(h.propogationDistance.String));%str2double(inputdlg('offset range'));
% codeLength = single(str2double(h.codeLength.String));
% sampleFreq= (str2double(h.sampleFreq.String));
% inOutDir = h.dataFolder.String;
fprintf('reading X0 data...');
framesFiles = dirRecursive(inoutFolder,'*.bin');
isSplitted = cellfun(@(x) ~isempty(strfind(x,'Splitted')),framesFiles);
framesFiles=framesFiles(isSplitted);
if(isempty(framesFiles))
    errordlg('No splitted bin files found');
    return
end
[ascDataFull] = cellfun(@(i) readRawframe(i),framesFiles,'uni',false);
fprintf('done(%d:%s)\n',length(ascDataFull),mat2str(cellfun(@(x) length(x),ascDataFull)'));

% tmplLength = double(codeLength*sampleRate);



%%
fprintf('reading XPC data...');
scopeFile = dirRecursive(inoutFolder,'*.h5');
scopeFile = scopeFile{1};

xpcDataFull = readLocation(scopeFile,mirrorFlavor); % Choose Mirror Type 'A' or 'B'
fprintf('done(%d:%s)\n',length(xpcDataFull),mat2str(cellfun(@(x) length(x),xpcDataFull)'));



if(nFrameSkip>0)
    xpcDataFull=xpcDataFull(nFrameSkip+1:end);%asic 1st frame drop
elseif(nFrameSkip<0)
    ascDataFull = ascDataFull(-nFrameSkip+1:end);
end


nframes = min(length(xpcDataFull),length(ascDataFull));

fprintf('starting frame by frame calcs(%d)...\n',nframes);
for frameNum=1:nframes
    %%
    fprintf('%d/%d\t',frameNum,nframes);
    %eval scale
    xpcSyncLocs = ([xpcDataFull{frameNum}.t0]-xpcDataFull{frameNum}(1).t0)*1e9;
    asicSyncLocs=double(([ascDataFull{frameNum}.timestamp]-uint64([ascDataFull{frameNum}.vSyncDelay])))/64*8;
    lfit = @(x) [(1:length(x))' x(:)*0+1]\(x(:)-x(1));
    xpc_m = lfit(xpcSyncLocs);
    asc_m = lfit(asicSyncLocs);
    scaleFactor=xpc_m(1)/asc_m(1);
    asicSyncLocs = asicSyncLocs*scaleFactor;
    fprintf('scaleFactor=%f\t',scaleFactor);
    
    
    
    %
    %correlate XPC and ASIC vsyncs
    precut=50;
    indMap = bsxfun(@plus,(1:length(asicSyncLocs)-precut*2)',0:length(xpcSyncLocs)-length(asicSyncLocs)+precut*2);
    c = (sum(abs(bsxfun(@minus,diff(xpcSyncLocs(indMap)),diff(asicSyncLocs(precut+1:end-precut)')))));
    cm = minind(c)-precut-1;
    %      cm = 20
    if(cm>0)
        xpcLocs=xpcDataFull{frameNum}(cm+1:end);
    x0Data = ascDataFull{frameNum};
    else
        xpcLocs=xpcDataFull{frameNum};
        x0Data = ascDataFull{frameNum}(-cm+1:end);
    end
    fprintf('#XPC=%d\t',length(xpcLocs));
    fprintf('#X0=%d\t',length(x0Data));
    
    nVscans = min(length(xpcLocs),length(x0Data));
    
    x0Data = x0Data(1:nVscans);
    xpcLocs = xpcLocs(1:nVscans);
    
    
    
    
    
    %
    asicSyncLocs2=double(([x0Data.timestamp]-uint64([x0Data.vSyncDelay])))/64*8*scaleFactor;
    xpcSyncLocs2 = ([xpcLocs.t0]-xpcLocs(1).t0)*1e9;
    fprintf('rms=%f\t',sqrt(mean((diff(asicSyncLocs2-xpcSyncLocs2).^2))));
    if(verbose)
        %%
        figure(3431);
        subplot(211)
        plot(diff(xpcSyncLocs));
        hold on
        plot(diff(asicSyncLocs));
        hold off
        title('before');
        subplot(212);
        
        
        zzz=xpcSyncLocs2(1:nVscans)-(asicSyncLocs2(1:nVscans))*scaleFactor;
        plot(zzz(2:end)-mean(zzz));
        plot(diff(xpcSyncLocs2));
        hold on
        plot(diff(asicSyncLocs2));
        hold off
        
        drawnow;
        title('after');
        legend('XPC','ASIC')
    end
    
    %% sync from v-syncs
    
    for i=1:nVscans
        
        xyI = [xpcLocs(i).angxQ;xpcLocs(i).angyQ];
        nout = length(x0Data(i).slow);
        nin  = size(xyI,2);
        x0Data(i).xy = int16(interp1(linspace(0,1,nin), xyI',linspace(0,1,nout)))';
        x0Data(i).xy = max(-2^11+1,min(2^11-1,x0Data(i).xy));
        xy4ivs = [x0Data.xy ];
    end
    %create IVS
    ivs.fast = [x0Data.fast];
    ivs.slow = [x0Data.slow];
    ivs.flags= [x0Data.flags];
    ivs.xy = xy4ivs;
    fprintf('writing ivs...');
    ivsfn = fullfile(inoutFolder,sprintf('record_%02d.ivs',frameNum));
    io.writeIVS(ivsfn,ivs);
    fprintf('done\n');
    
    
end




fprintf('Done\n');
end

