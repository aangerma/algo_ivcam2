function readFramesGUI()
% mcc -m readFramesGUI.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\readFrames\'

%%
W=500;
H=110;

DEF_FOLDER = 'C:\Users\ychechik\Desktop\171122\Frames\MIPI_0';

h.f = figure('name','read frames','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);

lh=22;
stride = 25;
currH = H-stride;

%input dir
uicontrol('style','text','units','pixels','position',[10 currH 120 lh],'String','data folder','horizontalalignment','left','parent',h.f);
h.dataFolder = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',DEF_FOLDER,'horizontalalignment','left','parent',h.f,'callback',@callbackDataEdit);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.dataFolder,true});

%out dir
currH = currH-stride;
h.outDir.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','out folder','horizontalalignment','left','parent',h.f);
h.outDir.edit = uicontrol('style','edit','units','pixels','position',[120 currH 320 lh],'String',fullfile(DEF_FOLDER,'out'),'horizontalalignment','left','parent',h.f);
uicontrol('style','pushbutton','units','pixels','position',[120+320 currH lh lh],'String','...','horizontalalignment','left','parent',h.f,'callback',{@callbackChoose,h.outDir,true});

%num frames
currH = currH-stride;
h.numFrames.checkbox = uicontrol('style','checkbox','units','pixels','position',[10 currH 120 lh],'String','numFrames','horizontalalignment','left','parent',h.f,'Value',1);
h.numFrames.edit = uicontrol('style','edit','units','pixels','position',[120 currH lh*2 lh],'String','3','parent',h.f);

%xy
h.verbose = uicontrol('style','checkbox','units','pixels','position',[250 currH 120 lh],'String','show xy','horizontalalignment','left','parent',h.f,'Value',0);


%read frames
currH = currH-stride;
uicontrol('style','pushbutton','units','pixels','position',[10 currH W-20 lh],'String','run','parent',h.f,'callback',@callback_runReadFrames);


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

function callbackDataEdit(varargin)
h=guidata(varargin{1});
h.outDir.edit.String = fullfile(h.dataFolder.String,'out');
end




function callback_runReadFrames(varargin)
h=guidata(varargin{1});

if(h.numFrames.checkbox.Value==0)
    ivsArr = io.FG.readFrames(h.dataFolder.String);
else
    ivsArr = io.FG.readFrames(h.dataFolder.String,'numFrames',str2double(h.numFrames.edit.String));
end


%% verbose
if(h.verbose.Value>0)
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


%% calib
f = figure;
maximize(f);
d = Calibration.aux.mSyncerPipe(ivsArr(1),[],true);

%% show
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
    outDir = h.outDir.edit.String;
    mkdirSafe(outDir);
    
    %write ivs + gif
    outfn = fullfile(outDir,'ir.gif');
    for i=1:length(ivsArr)
        io.writeIVS(ivsArr(i),fullfile(outDir,sprintf('record_%02d.ivs',i)));
        
        [imind,cm] = rgb2ind(repmat(im{i},1,1,3),256);
        if(i==1)
            imwrite(imind,cm,outfn,'gif', 'Loopcount',inf);
        else
            imwrite(imind,cm,outfn,'gif','WriteMode','append');
        end
    end
end


end





