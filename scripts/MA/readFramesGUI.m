function readFramesGUI()
% matlab 2015a !!!
% deploytool
% library compiler
% .NET assembly
% add POC4analyzer.m & runPipe.m
% library name: POC4analyzer
% class name : POC4
% files req... : add 'tables' dir
% finish

% mcc -m readFramesGUI.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\readFrames\'


%%

W=500;
H=110;

DEF_FOLDER = 'C:\Users\ychechik\Desktop\171122\Frames\MIPI_0';

h.f = figure('name','read frames','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);

% warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
% jframe=get(gcf,'javaframe');
% ic=javax.swing.ImageIcon('./POCanalyzer_resources/icon_48.png');
% jframe.setFigureIcon(ic);

lh=22;
stride = 25;
currH = H-stride;

%input dir
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','data folder','horizontalalignment','left','parent',h.f);
h.dataFolder = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',DEF_FOLDER,'horizontalalignment','left','parent',h.f);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.dataFolder,true});

currH = currH-stride;
h.outDir.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','out folder','horizontalalignment','left','parent',h.f);
h.outDir.edit = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String','...','horizontalalignment','left','parent',h.f);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.outDir,true});

currH = currH-stride;
h.numFrames.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','numFrames','horizontalalignment','left','parent',h.f,'Value',1);
% uicontrol('style','text','units','pixels','position',[10+lh currH 120 lh],'String','numFrames','horizontalalignment','left','parent',h.f);
h.numFrames.edit = uicontrol('style','edit','units','pixels','position',[120 currH lh*2 lh],'String','3','parent',h.f);

h.verbose = uicontrol('style','checkbox','units','pixels','position',[250 currH 120 lh],'String','show xy','horizontalalignment','left','parent',h.f,'Value',1);



currH = currH-stride;

%generate IVS
uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','run','parent',h.f,'callback',@callback_runReadFrames);
% currH = currH-stride;
% uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','PIPE','parent',h.f,'callback',@callback_runPipe);


guidata(h.f,h);

end

function callbackChoose(varargin)
h=guidata(varargin{1});
hh=varargin{3};
if(varargin{4})
    d = uigetdir(hh.String);
else
    [FileName,PathName] = uigetfile(hh.String);
    d=fullfile(PathName,filesep,FileName);
end
if(~isa(d,'numeric'))
    hh.String = d;
end
end

function callback_runReadFrames(varargin)
h=guidata(varargin{1});

if(h.numFrames.checkbox.Value==0)
    ivsArr = io.FG.readFrames(h.dataFolder.String,'verbose',h.verbose.Value>0);
else
    ivsArr = io.FG.readFrames(h.dataFolder.String,'numFrames',str2double(h.numFrames.edit.String),'verbose',h.verbose.Value>0);
end





%% calib
f = figure;
maximize(f);
d = Calibration.aux.mSyncerPipe(ivsArr{1},[],true);

%% show
im = cell(length(ivsArr),1);
for i=1:length(ivsArr)
    im{i} = Utils.raw2img(ivsArr{i},d,[512 512]);
end


figure;
for i=1:length(ivsArr)
    tabplot;
    imagesc(im{i}); colormap gray
end

%% save
if(h.outDir.checkbox.Value==1)
    outDir = h.outDir.edit.String;
    mkdirSafe(outDir);
    
    for i=1:length(ivsArr)
        io.writeIVS(ivsArr{i},fullfile(outDir,sprintf('record_%02d.ivs',i)));
        
        mx = max(vec(im{i}));mn = min(vec(im{i}));
        im{i} = double(im{i}-mn)/double(mx-mn);
        imwrite(im{i},fullfile(outDir,sprintf('record_%02d.png',i)));
    end
end

% % % outfn = fullfile(outDir,'ir.gif');
% % % if(length(ivsArr)==1)
% % %     imwrite(im{1},outfn,'gif', 'Loopcount',inf);
% % % else
% % %     for i=1:length(ivsArr)
% % %         imwrite(im{i},outfn,'gif','WriteMode','append');
% % %     end
% % % end
% % % 
% % % [A,map]=imread(outfn,'frames','all');
% % % mov=immovie(A,map);
% % % implay(mov)


end





