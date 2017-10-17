function compareViewer(varargin)
% COMPAREVIEWER is a GUI based function that lets you compare two given
% images.
%Several input types to this function:
% no input - regular use.
% one input - input should be a path to default dir.
% two inputs - inputs are 2 images to compare


if(nargin==1)
    if(~isa(varargin{1},'char'))
        error('for one input- input should be a string of default path');
    end
    if(~isdir(varargin{1}))
        error('input should be a valid path');
    end
elseif(nargin == 2 && ~isa(varargin{1},'numeric') && ~isa(varargin{2},'numeric')    )
    error('2 inputs should be images');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main panels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WIN_H = 750;
WIN_W = 1800;

h.f = figure('units','pixels','menubar','none','pos',[0 0 WIN_W WIN_H],...
    'toolbar','figure','numberTitle','off','name','compareViewer');

h.inputImage1 = [];
h.inputImage2 = [];
h.firstMousePress = [];
h.line = [];
guidata(h.f,h);

createGUI(h);

h= guidata(h.f);
centerfig(h.f);
h= guidata(h.f);
guidata(h.f,h);

if(length(varargin)==1) %varargin{1} is defDirName
    defDirName = varargin{1};
    h.GUI.comp1_dir_edit.String = defDirName;
    h.GUI.comp2_dir_edit.String = defDirName;
end
if(length(varargin)==2) %two input pictures
    h.inputImage1 = varargin{1};
    h.inputImage2 = varargin{2};
    h.GUI.comp1_dir_edit.String = 'FROM INPUT';
    h.GUI.comp2_dir_edit.String = 'FROM INPUT';
    
    h.GUI.comp1_dir_button.Enable = 'off';
    h.GUI.comp2_dir_button.Enable = 'off';
    h.GUI.comp1_dir_edit.Enable = 'off';
    h.GUI.comp2_dir_edit.Enable = 'off';
    set(h.GUI.bg.Children(1:3),'Enable','off');
    h.GUI.runButton.Enable = 'off';
    
    guidata(h.f,h);
    runfnc(h.f);
end
end

function createGUI(varargin)
if(nargin==1)
    h = varargin{1};
else
    h= guidata(varargin{1});
end
clf(h.f);

ROW_H = 20;

p = get(h.f,'pos');
psz = p(3:4);

MRGN=3;
LCL_W = 300;
RCL_W = psz(1)-LCL_W-2*MRGN;

txtW = 100;
buttonW = 40;
editW = 250;

posInput = [MRGN   MRGN   LCL_W   psz(2)];
posImages = [LCL_W+MRGN   MRGN   RCL_W   psz(2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input panel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h.GUI.input = uipanel('Parent',h.f,'title','Params:',...
    'units','pixels','fontsize',10,...
    'Position',posInput,'Visible','on');

psz = get(h.GUI.input,'pos');psz=psz(3:4);

Hcurrent = psz(2)-2*ROW_H;

% Hcurrent = Hcurrent-2*ROW_H;
%
Hcurrent = Hcurrent-2*ROW_H;

% comp 1
h.GUI.comp1 = uipanel('parent',h.GUI.input,...
    'units','pixels','pos',[1    Hcurrent   psz(1)-2*MRGN     3*ROW_H] ,'BorderType','none','tag','1');
uicontrol('Style','text','parent',h.GUI.comp1,'units','pixels',...
    'pos',[1 1.5*ROW_H txtW ROW_H],'string','choose comp1:',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.GUI.comp1_dir_edit = uicontrol('Style','edit','parent',h.GUI.comp1,'units','pixels',...
    'pos',[1    0.5*ROW_H   editW    ROW_H],'horizontalAlignment','left','fontsize',10,...
    'backgroundcolor','w','String','...','Enable','on','Tag','dir');
uicontrol(h.GUI.comp1,'Style','pushbutton','String','...',...
    'Position',[1+editW+5    0.5*ROW_H   ROW_H    ROW_H],'Enable','on','Tag','dir','Callback',@choose_file_fnc);


Hcurrent = Hcurrent-3*ROW_H;

% comp 2
h.GUI.comp2 = uipanel('parent',h.GUI.input,...
    'units','pixels','pos',[1    Hcurrent   psz(1)-2*MRGN     3*ROW_H] ,'BorderType','none','tag','1');
uicontrol('Style','text','parent',h.GUI.comp2,'units','pixels',...
    'pos',[1 1.5*ROW_H txtW ROW_H],'string','choose comp2:',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.GUI.comp2_dir_edit = uicontrol('Style','edit','parent',h.GUI.comp2,'units','pixels',...
    'pos',[1    0.5*ROW_H   editW    ROW_H],'horizontalAlignment','left','fontsize',10,...
    'backgroundcolor','w','String','...','Enable','on','Tag','dir');
uicontrol(h.GUI.comp2,'Style','pushbutton','String','...',...
    'Position',[1+editW+5    0.5*ROW_H   ROW_H    ROW_H],'Enable','on','Tag','dir','Callback',@choose_file_fnc);

Hcurrent = Hcurrent-2*ROW_H;

% ir/z/c buttongroup
h.GUI.bg = uibuttongroup('parent',h.GUI.input,...
    'units','pixels','pos',[1    Hcurrent   psz(1)-2*MRGN     ROW_H],'BorderType','none');
uicontrol('Style','text','parent',h.GUI.bg,'units','pixels',...
    'pos',[1 1 txtW ROW_H],'string','chose image:',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
uicontrol(h.GUI.bg,'Style','radiobutton',...
    'String','IR',...
    'Position',[1+txtW    1   buttonW    ROW_H]);
uicontrol(h.GUI.bg,'Style','radiobutton',...
    'String','Z',...
    'Position',[1+buttonW+MRGN+txtW    1   buttonW    ROW_H]);
uicontrol(h.GUI.bg,'Style','radiobutton',...
    'String','C',...
    'Position',[1+2*(buttonW+MRGN)+txtW    1   buttonW    ROW_H]);
Hcurrent = Hcurrent-2*ROW_H;

%run button
h.GUI.runButton = uicontrol('Style','pushbutton','parent',h.GUI.input,'units','pixels',...
    'pos',[1 Hcurrent psz(1)-3 ROW_H],'string','RUN',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'Callback',@runfnc);

Hcurrent = Hcurrent-2*ROW_H;

%viewer button
uicontrol('Style','pushbutton','parent',h.GUI.input,'units','pixels',...
    'pos',[1 Hcurrent psz(1)-3 ROW_H],'string','show Z image in viewer',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'Callback',@viewerfnc);

Hcurrent = Hcurrent-2*ROW_H;

%profile axes
winH = 200;
h.GUI.profile = axes('Parent', h.GUI.input, ...
    'Units', 'pixels', 'NextPlot','add',...
    'Position',[35 Hcurrent-winH psz(1)-50 winH]);
title(h.GUI.profile,'profile');
grid(h.GUI.profile);

Hcurrent = Hcurrent-2*ROW_H-winH;

%clear button
uicontrol('Style','pushbutton','parent',h.GUI.input,'units','pixels',...
    'pos',[1 Hcurrent txtW ROW_H],'string','clear lines',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'Callback',@clear_ax_fnc);

Hcurrent = Hcurrent-2*ROW_H;

%caxis sliders
pos_sliders_title = [5 Hcurrent psz(1)-10 20];
uicontrol('Style','text','parent',h.GUI.input,'units','pixels',...
    'pos',pos_sliders_title,'string','color limit sliders:',...
    'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));

Hcurrent = Hcurrent-1.1*ROW_H;
pos_min_color_slider = [5 Hcurrent psz(1)-10 20];
Hcurrent = Hcurrent-1.1*ROW_H;
pos_max_color_slider = [5 Hcurrent psz(1)-10 20];

h.GUI.min_color_slider = uicontrol('Parent',h.GUI.input,'Style', 'slider',...
    'Min',0,'Max',1,'Value',0,...
    'Position',pos_min_color_slider,...
    'Callback', @callback_slider);
h.GUI.max_color_slider = uicontrol('Parent',h.GUI.input,'Style', 'slider',...
    'Min',0,'Max',1,'Value',1,...
    'Position', pos_max_color_slider,...
    'Callback', @callback_slider);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% images panel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h.GUI.images = uipanel('Parent',h.f,'title','Comparison:',...
    'units','pixels','fontsize',10,...
    'Position',posImages,'Visible','on');

psz = get(h.GUI.images,'pos');psz=psz(3:4);

imW = floor(psz(1)/2)-40;
imH = psz(2)-60;
% comp1 image panel
posCmp1Axes = [MRGN+30 MRGN+20 imW imH ];
h.GUI.comp1 = axes('Parent', h.GUI.images, ...
    'Units', 'pixels', 'NextPlot','add',...
    'Position',posCmp1Axes,'ButtonDownFcn', @drawfnc);
h.GUI.comp1.YDir = 'reverse';
axis(h.GUI.comp1,'image');

% comp2 image panel
posCmp2Axes = [MRGN+30+posCmp1Axes(1)+imW    MRGN+20    imW    imH ];
h.GUI.comp2 = axes('Parent', h.GUI.images, ...
    'Units', 'pixels', 'NextPlot','add',...
    'Position',posCmp2Axes,'ButtonDownFcn', @drawfnc);
h.GUI.comp2.YDir = 'reverse';
axis(h.GUI.comp2,'image');


% set(h.f,'SizeChangedFcn',@createGUI);
guidata(h.f,h);

end


function callback_slider(varargin)
h= guidata(varargin{1});

maxV = h.GUI.max_color_slider.Value;
minV = h.GUI.min_color_slider.Value;
if(minV>=maxV) %not valid
    h.GUI.max_color_slider.Value = h.GUI.max_color_slider.UserData;
    h.GUI.min_color_slider.Value = h.GUI.min_color_slider.UserData;
else
    colorLim = [minV, maxV];
    caxis(h.GUI.comp1,colorLim);
    caxis(h.GUI.comp2,colorLim);
    h.GUI.max_color_slider.UserData = h.GUI.max_color_slider.Value;
    h.GUI.min_color_slider.UserData = h.GUI.min_color_slider.Value;
end

end

function choose_file_fnc(varargin)
h = guidata(varargin{1});
setWatches(h,false);
ind = strcmp({varargin{1}.Parent.Children(:).Style},'edit');
num = str2double(varargin{1}.Parent.Tag);

def_path = '\\invcam322\Ohad\data\lidar\EXP\';

path = h.GUI.(['comp' num2str(num) '_dir_edit']).String;
if(strcmp(path,'...'))
    other_dir = h.GUI.(['comp' num2str(2-num+1) '_dir_edit']).String;
    if(strcmp(other_dir,'...'))
        path = def_path;
    else
        path = other_dir;
    end
end


[FileName,PathName] = uigetfile('*.bin*','Select one .bin*, we will take them all :)',path);
given_path = [PathName '\' FileName];
if(strcmp(given_path,[0 '\' 0]))%exits the getfile gui
    given_path = '...';
else
    last_sep = strfind(given_path,'\');
    last_sep = last_sep(end);
    given_path = given_path(1:last_sep-1);
end

varargin{1}.Parent.Children(ind).String = given_path;

setWatches(h,true);
end



function runfnc(varargin)
try
    h = guidata(varargin{1});
    setWatches(h,false);
    clear_ax_fnc(h.f);
    
    [comp1, comp2] = get_comp(h);
    
    if(strcmp(h.GUI.bg.SelectedObject.String, 'IR'))
        im_type = 'ibin';
        h.im_comp1 = comp1.(im_type);
        h.im_comp2 = comp2.(im_type);
        cla(h.GUI.comp1);
        imagesc(h.im_comp1,'parent',h.GUI.comp1,'hittest','off');
        %         caxis(h.GUI.comp1,'auto');
        colormap(h.GUI.comp1,'gray');
        axis(h.GUI.comp1,'image');
        
        cla(h.GUI.comp2);
        imagesc(h.im_comp2,'parent',h.GUI.comp2,'hittest','off');
        %         caxis(h.GUI.comp2,'auto');
        colormap(h.GUI.comp2,'gray');
        axis(h.GUI.comp2,'image');
        
    elseif(strcmp(h.GUI.bg.SelectedObject.String, 'Z'))
        im_type = 'zbin';
        h.im_comp1 = comp1.(im_type);
        h.im_comp2 = comp2.(im_type);
        cla(h.GUI.comp1);
        imagesc(h.im_comp1,'parent',h.GUI.comp1,'hittest','off');
        %         caxis(h.GUI.comp1,prctile(double(h.im_comp1(:)),[10 90]));
        colormap(h.GUI.comp1,'default');
        axis(h.GUI.comp1,'equal');
        
        cla(h.GUI.comp2);
        imagesc(h.im_comp2,'parent',h.GUI.comp2,'hittest','off');
        %         caxis(h.GUI.comp2,prctile(double(h.im_comp2(:)),[10 90]));
        colormap(h.GUI.comp2,'default');
        axis(h.GUI.comp2,'image');
    else %C
        im_type = 'cbin';
        h.im_comp1 = comp1.(im_type);
        h.im_comp2 = comp2.(im_type);
        cla(h.GUI.comp1);
        imagesc(h.im_comp1,'parent',h.GUI.comp1,'hittest','off');
        %         caxis(h.GUI.comp1,prctile(double(h.im_comp1(:)),[10 90]));
        colormap(h.GUI.comp1,'default');
        axis(h.GUI.comp1,'equal');
        
        cla(h.GUI.comp2);
        imagesc(h.im_comp2,'parent',h.GUI.comp2,'hittest','off');
        %         caxis(h.GUI.comp2,prctile(double(h.im_comp2(:)),[10 90]));
        colormap(h.GUI.comp2,'default');
        axis(h.GUI.comp2,'image');
    end
    linkaxes([h.GUI.comp1,h.GUI.comp2]);
    title(h.GUI.comp1,comp1.name,'Interpreter', 'none');
    title(h.GUI.comp2,comp2.name,'Interpreter', 'none');
    
    %unified caxis for sliders:
    colorLim = [min([h.im_comp1(:); h.im_comp2(:)]) ,max([h.im_comp1(:); h.im_comp2(:)])];
    caxis(h.GUI.comp1,colorLim);
    caxis(h.GUI.comp2,colorLim);
    h.GUI.min_color_slider.Min = colorLim(1);
    h.GUI.min_color_slider.Max = colorLim(2);
    h.GUI.max_color_slider.Min = colorLim(1);
    h.GUI.max_color_slider.Max = colorLim(2);
    h.GUI.min_color_slider.Value = colorLim(1);
    h.GUI.max_color_slider.Value = colorLim(2);
    h.GUI.min_color_slider.UserData = colorLim(1);%will work as last valid place of slider
    h.GUI.max_color_slider.UserData = colorLim(2);
    
    setWatches(h,true);
    
    guidata(h.f, h);
    
catch e
    setWatches(h,true);
    errordlg(e.message);
end
end







function [comp1, comp2] = get_comp(h)

if(isempty(h.inputImage1))
    s=struct;
    for i=1:2
        
        dn = h.GUI.(['comp' num2str(i) '_dir_edit']).String;
        f = dir(dn);
        ff = {f.name};
        ff([f.isdir]) = [];
        
        if(isempty(ff))
            error(['no such dir comp' num2str(i) ': ' dn ])
        end
        
        bin_fn = cellfun(@(x) ~isempty(strfind(x,'.bini')) , ff);
        if(all(~bin_fn))
            error(['no .bini in comp' num2str(i) ': ' dn ])
        end
        bin_fn = ff{find(bin_fn==1,1,'last')};
        s.(['comp' num2str(i)]).ibin = io.readBin([dn filesep bin_fn]).';
        
        bin_fn = cellfun(@(x) ~isempty(strfind(x,'.binz')) , ff);
        if(all(~bin_fn))
            error(['no .binz in comp' num2str(i) ': ' dn ])
        end
        bin_fn = ff{find(bin_fn==1,1,'last')};
        s.(['comp' num2str(i)]).zbin = io.readBin([dn filesep bin_fn]).';
        
        bin_fn = cellfun(@(x) ~isempty(strfind(x,'.binc')) , ff);
        if(all(~bin_fn))
            error(['no .binc in comp' num2str(i) ': ' dn ])
        end
        bin_fn = ff{find(bin_fn==1,1,'last')};
        s.(['comp' num2str(i)]).cbin = io.readBin([dn filesep bin_fn]).';
        
        %get name
        sep_place = strfind(dn,'\');
        if(sep_place(end) == length(dn))
            if(length(sep_place)>1)
                last_sep = sep_place(end-1);
            else
                last_sep = 1;
            end
        else
            last_sep = sep_place(end);
        end
        name = dn(last_sep+1:end);
        if(name(end)=='\')
            name = name(1:end-1);
        end
        s.(['comp' num2str(i)]).name = name;
        
        
    end
    comp1 = s.comp1;
    comp2 = s.comp2;
else
    comp1.cbin = h.inputImage1;
    comp1.ibin = h.inputImage1;
    comp1.zbin = h.inputImage1;
    comp1.name = 'Input Image 1';
    
    comp2.cbin = h.inputImage2;
    comp2.ibin = h.inputImage2;
    comp2.zbin = h.inputImage2;
    comp2.name = 'Input Image 2';
end
end












function viewerfnc(varargin)
try
    h= guidata(varargin{1});
    [comp1, comp2] = get_comp(h);
    im_type = 'zbin';
    im_comp1 = comp1.(im_type);
    im_comp2 = comp2.(im_type);
    ivbin_viewer(im_comp1.',im_comp2.');
    
catch e
    %     setWatches(h,true);
    errordlg(e.message);
end
end






function drawfnc(varargin)
h= guidata(varargin{1});
lw = 3;
if(isempty(h.firstMousePress))
    h.firstMousePress = [varargin{1}.CurrentPoint(1,1) varargin{1}.CurrentPoint(1,2)];
    set(gcf,'Pointer','crosshair');
else
    set(gcf,'Pointer','arrow');
    [x,ind]=sort([h.firstMousePress(1) varargin{1}.CurrentPoint(1,1)]);
    y=[h.firstMousePress(2) varargin{1}.CurrentPoint(1,2)];
    y = y(ind);
    color1 = rand(1,3);
    color2 = rand(1,3);
    if(isempty(h.line))
        h.line.comp1 = cell(1,1);
        h.line.comp2 = cell(1,1);
        h.line.comp1{1} = plot(h.GUI.comp1,x,y,'LineWidth',lw,'color',color1);
        h.line.comp2{1} = plot(h.GUI.comp2,x,y,'LineWidth',lw,'color',color2);
    else
        
        h.line.comp1{end+1} = plot(h.GUI.comp1,x,y,'LineWidth',lw,'color',color1);
        h.line.comp2{end+1} = plot(h.GUI.comp2,x,y,'LineWidth',lw,'color',color2);
    end
    
    a = improfile(h.im_comp1,x,y);
    b = improfile(h.im_comp2,x,y);
    plot(h.GUI.profile, a,'.','color',color1);
    plot(h.GUI.profile,b,'s','color',color2);
    h.firstMousePress = [];
    
end
guidata(h.f,h);


end







function clear_ax_fnc(varargin)
h= guidata(varargin{1});
if(~isempty(h.line))
    for i=1:length(h.line.comp1)
        delete(h.line.comp1{i});
        delete(h.line.comp2{i});
    end
    h.line =[];
    cla(h.GUI.profile);
    guidata(h.f,h);
end
end






function setWatches(h,mode)
if(isempty(h.inputImage1)) %else do nothing...
    modeString = 'off';
    ptr='watch';
    if mode
        modeString='on';
        ptr='arrow';
    end
    
    set(h.f,'Pointer',ptr);
    set(findobj(h.f,'style','pushbutton'),'Enable',modeString);
    
    drawnow;
end

end



