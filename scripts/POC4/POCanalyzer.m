function POCanalyzer(inoutFolder,verbose)
% matlab 2015a !!!
% deploytool
% library compiler
% .NET assembly
% add POC4analyzer.m & runPipe.m
% library name: POC4analyzer
% class name : POC4
% files req... : add 'tables' dir
% finish



if(nargin==0)
    buildGui();
else
    aux.runPOCanalyzer(inoutFolder,verbose);
end


end

function buildGui()
%%

W=500;
H=120;

DEF_FOLDER = 'd:\Ohad\data\lidar\EXP\20170424\7014MB4104DF\240417\POC4\8MHz\Chess_Board\';

h.f = figure('name','X0  analyzer','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);

warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jframe=get(gcf,'javaframe');
ic=javax.swing.ImageIcon('./POCanalyzer_resources/icon_48.png');
jframe.setFigureIcon(ic);

lh=22;
stride = 25;
currH = H-stride;

%input dir
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','data folder','horizontalalignment','left','parent',h.f);
h.dataFolder = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',DEF_FOLDER,'horizontalalignment','left','parent',h.f);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.dataFolder,true});

currH = currH-stride;
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','verbose','horizontalalignment','left','parent',h.f);
h.verbose = uicontrol('style','checkbox','units','pixels','position',[120 currH 2*lh lh],'value',0,'parent',h.f);
currH = currH-stride;

%generate IVS
uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','START','parent',h.f,'callback',@callback_runSync);
currH = currH-stride;
uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','PIPE','parent',h.f,'callback',@callback_runPipe);


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
    h.dataFolder.String = d;
end
end

function callback_runPipe(varargin)
h=guidata(varargin{1});
inoutFolder = h.dataFolder.String;
runPipe(inoutFolder)
end

function callback_runSync(varargin)
h=guidata(varargin{1});


inoutFolder = h.dataFolder.String;

verbose = h.verbose.Value;
set_watches(h.f,false);
try
    aux.runPOCanalyzer(inoutFolder,verbose);
catch e,
    ttt=getReport(e);
    tttNoTags=regexprep(regexprep(ttt,'errorDocCallback\([^\)]+\)',''),'<[^>]+>','');
    disp(ttt);
    errordlg(tttNoTags,'error','modal');
end
set_watches(h.f,true);

end


