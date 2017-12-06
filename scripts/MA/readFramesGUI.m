function readFramesGUI()
close all
% mcc -m readFramesGUI.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\readFrames\'

%%
W=490;
H=220;
NO_CB_T_OFFSET = -5; %no checkbox text offset - compered to text with checkbox combined...
nextColStartH = 140;

DEF_FOLDER = 'C:\Users\ychechik\Desktop\171122\Frames\MIPI_0';

h.f = figure('name','read frames','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);

lh=22;
stride = 25;
currH = H-stride;

%input dir
uicontrol('style','text','units','pixels','position',[10 currH+NO_CB_T_OFFSET 120 lh],'String','data folder','horizontalalignment','left','parent',h.f);
h.dataFolder = uicontrol('style','edit','units','pixels','position',[nextColStartH currH 320 lh],'String',DEF_FOLDER,'horizontalalignment','left','parent',h.f,'callback',@callbackDataEdit);
uicontrol('style','pushbutton','units','pixels','position',[nextColStartH+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.dataFolder,true});

%out dir
currH = currH-stride;
h.outDir.edit = uicontrol('style','edit','units','pixels','position',[nextColStartH currH 320 lh],'String',fullfile(DEF_FOLDER,'out'),'horizontalalignment','left','parent',h.f,'Enable','off');
h.outDir.pushbutton = uicontrol('style','pushbutton','units','pixels','position',[nextColStartH+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.outDir,true},'Enable','off');
guidata(h.f,h);
h.outDir.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 100 lh],'String','out folder (save)','horizontalalignment','left','parent',h.f,'callback',{@callbackCheckboxEnable,h.outDir.pushbutton,h.outDir.edit});

%num frames
currH = currH-stride;
h.numFrames.edit = uicontrol('style','edit','units','pixels','position',[nextColStartH currH lh*2 lh],'String','3','parent',h.f,'Enable','on');
guidata(h.f,h);
h.numFrames.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 100 lh],'String','numFrames','horizontalalignment','left','parent',h.f,'Value',1,'callback',{@callbackCheckboxEnable,h.numFrames.edit});

% sample rate
currH = currH-stride;
h.sampleRate.text = uicontrol('style','text','units','pixels','position',[10 currH+NO_CB_T_OFFSET 120 lh],'String','Sample rate [GHz]','horizontalalignment','left','parent',h.f);
h.sampleRate.popup = uicontrol('style','popup','units','pixels','position',[nextColStartH currH 50 lh],'String',{'8','16'},'horizontalalignment','left','parent',h.f,'Value',1);

%xy
currH = currH-stride;
h.xy = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','show xy','horizontalalignment','left','parent',h.f,'Value',0);

%fast FFT
currH = currH-stride;
h.fastFFT = uicontrol('style','checkbox','units','pixels','position',[10 currH 100 lh],'String','Fast FFT','horizontalalignment','left','parent',h.f,'Value',0);

%slow-xy delay
currH = currH-stride;
h.calib.edit = uicontrol('style','edit','units','pixels','position',[nextColStartH currH lh*2 lh],'String','1000','parent',h.f,'Enable','off');
guidata(h.f,h);
h.calib.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','ir-xy delay [nSec]','horizontalalignment','left','parent',h.f,'Value',0,'callback',{@callbackCheckboxEnable,h.calib.edit});

%run
currH = currH-stride;
uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','run','parent',h.f,'callback',@callback_runReadFrames);

%disptext
currH = currH-stride;
h.dispText = uicontrol('style','text','units','pixels','position',[10 currH W-20 lh],'String','ready','horizontalalignment','center','parent',h.f);

guidata(h.f,h);

end

function callbackCheckboxEnable(varargin)
for i=3:length(varargin)
    varargin{i}.Enable = iff(strcmp(varargin{i}.Enable,'on'),'off','on');
end
end

function callbackChoose(varargin)
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

function callbackDataEdit(varargin)
h=guidata(varargin{1});
h.outDir.edit.String = fullfile(h.dataFolder.String,'out');
end




function callback_runReadFrames(varargin)
h=guidata(varargin{1});

sampleRate = str2double(h.sampleRate.popup.String{h.sampleRate.popup.Value})*1e9;

h.dispText.String = 'reading frames...';
refreshdata(h.f);drawnow;


if(h.numFrames.checkbox.Value==0)
    ivsArr = io.FG.readFrames(h.dataFolder.String);
else
    ivsArr = io.FG.readFrames(h.dataFolder.String,'numFrames',str2double(h.numFrames.edit.String));
end


%% xy
if(h.xy.Value>0)
    h.dispText.String = 'genereting xy maps...';
    refreshdata(h.f);drawnow;
    
    fxy = figure(2452);clf;
    fx = figure(24852);clf;
    fy = figure(245892);clf;
    
    for i=1:length(ivsArr)
        xy = ivsArr(i).xy;
        
        figure(fxy);
        tabplot;hold on;
        plot(xy(1,:),xy(2,:),'*');
        title('xy')
        
        
        t=(0:length(ivsArr(i).slow)-1)/8e9;
        figure(fx);tabplot;
        plot(t,xy(1,:),'*');
        title('x')
        
        figure(fy);tabplot;
        plot(t,xy(2,:),'*');
        title('y')
    end
end

%% fast FFT
if(h.fastFFT.Value>0)
    h.dispText.String = 'genereting FFTs...';
    refreshdata(h.f);drawnow;
    
    figure(2452421);
    for i=1:length(ivsArr)
        fast = ivsArr(i).fast;
        tabplot;
        fftplot(fast,sampleRate);
        title('fast FFT')
    end
end


%% calib
if(h.calib.checkbox.Value==0)
    h.dispText.String = 'calibrating...';
    refreshdata(h.f);drawnow;
    
%     f = figure(4652352);clf;
%     maximize(f);
    d = Calibration.aux.mSyncerPipe(ivsArr(1),[],false);
    msgbox({...
        ['slow-xy deley in samples = ' num2str(d)]...
        ['slow-xy deley in nSec = ' num2str(d*sampleRate/1e9)]},'delay');
else
    d = str2double(h.calib.edit.String)/sampleRate*1e9;
end

%% show
h.dispText.String = 'genereting IR output images...';
refreshdata(h.f);drawnow;

figure(124234);clf
im = cell(length(ivsArr),1);
for i=1:length(ivsArr)
    im{i} = Utils.raw2img(ivsArr(i),d,[512 512]);
    
    mx = max(vec(im{i}));mn = min(vec(im{i}));
    im{i} = double(im{i}-mn)/double(mx-mn);
    im{i}(isnan(im{i})) = 0;
    
    tabplot;
    imagesc(im{i}); colormap gray
end

%% save
if(h.outDir.checkbox.Value==1)
    h.dispText.String = 'saving...';
    refreshdata(h.f);drawnow;
    
    outDir = h.outDir.edit.String;
    mkdirSafe(outDir);
    
    %write ivs + gif
    outfn = fullfile(outDir,'ir.gif');
    for i=1:length(ivsArr)
        io.writeIVS(ivsArr(i),fullfile(outDir,sprintf('record_%02d.ivs',i)));       
        imwriteAnimatedGif(im,outfn)
    end
end



h.dispText.String = 'Done!';
refreshdata(h.f);drawnow;
end





