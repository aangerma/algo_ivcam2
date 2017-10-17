function test_JFIL(pflow,dRegs)
h.images_zoom = [1 1];

h.colorBarsVal.Z = [0 0];
h.colorBarsVal.IR = [0 0];
h.colorBarsVal.C = [0 0];

REG_H = 20;
WINDOW_H = 720;
WINDOW_W = 1400;
h.input.zImgRAW = pflow.zImgRAW;
h.input.iImgRAW = pflow.iImgRAW;
h.input.cImgRAW = pflow.cImgRAW;
[h.regs, h.luts] = Firmware().get();
if exist('dRegs','var')
    h.regs = dRegs;
end
h.defRegs = h.regs;
h.regNames = fieldnames(h.regs.JFIL);
h.regNames = sort(h.regNames);
h.regNames = h.regNames(end:-1:1);

pos_figure = [250 250 WINDOW_W WINDOW_H];
h.f = figure('numbertitle','off','name','JFIL Test','windowscrollWheelFcn',@callback_windowscrollWheelFcn,'SizeChangedFcn',@sbar,'Position',pos_figure);
h.lastPos = h.f.Position;
h.MinSize = h.lastPos(3:4);

% [h.outputImages.zImgRAW, h.outputImages.iImgRAW, h.outputImages.cImgRAW, ~] = Pipe.JFIL.JFIL(h.input,h.regs,h.luts,Logger(),[]);
% h.colorBarsVal.Z = [min(h.outputImages.zImgRAW(:)) max(h.outputImages.zImgRAW(:))];
% h.colorBarsVal.IR = [min(h.outputImages.iImgRAW(:)) max(h.outputImages.iImgRAW(:))];
% h.colorBarsVal.C = [min(h.outputImages.cImgRAW(:)) max(h.outputImages.cImgRAW(:))];


pos_panel1 = [0 0 h.f.Position(3)*.25 h.f.Position(4)];
pos_panel2 = [ 0 0 pos_panel1(3)*0.95 size(h.regNames,1)*REG_H] ;
pos_sld = [pos_panel2(3) 0 pos_panel1(3)*0.05 pos_panel1(4)];

pos_images_panel = [pos_panel1(3) 0 h.f.Position(3)*.65 h.f.Position(4)];
pos_controls_panel = [pos_images_panel(1)+pos_images_panel(3) 0 h.f.Position(3)*.1 h.f.Position(4)];
pos_out_images_panel = [0 0 pos_images_panel(3) pos_images_panel(4)/2];
pos_in_images_panel = [0 pos_out_images_panel(4) pos_out_images_panel(3) pos_images_panel(4)/2];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% create images panel %%%%%%%%%%%%%%%%%%%%%%%%%%%
h.images_panel = uipanel('Parent',h.f,'Units','pixels','Position',pos_images_panel);

h.input_images_panel = uipanel('Parent',h.images_panel,'Units','pixels','title','Input Images','Position',pos_in_images_panel);
h.output_images_panel = uipanel('Parent',h.images_panel,'Units','pixels','title','JFIL Results','Position',pos_out_images_panel);

h.panel1 = uipanel('Parent',h.f,'Units','pixels','borderType','none');
h.panel1.Position = pos_panel1;
h.panel1.BackgroundColor = [1 1 1 1];

h.panel2 = uipanel('Parent',h.panel1,'Units','pixels','borderType','none');
h.panel2.Position = pos_panel2;
h.panel2.BackgroundColor = [.9 .9 .9 .9];
h.hsld = uicontrol('style','slider','parent',h.panel1,'Callback',@callback_updatePanel2Pos);
h.hsld.Position = pos_sld;


%fill all registers controls grouped by blocks
blocksPart = BolcksRegsPatition(h.regNames);
controlPos = [0 0 h.panel2.Position(3)/2 REG_H];

h.regControls = {};
for j = 1:length(blocksPart)
    for i = 1:length(blocksPart{j}.regs)
        regN = blocksPart{j}.regs(i);
        regN = regN{1};
        regV = h.regs.JFIL.(regN);
        regType = class(regV);
        name = uicontrol('style','text','string',['  ' regN '(' num2str(length(regV)) 'x' regType(1:3) regType(end-1:end) '):'],'parent',h.panel2);
        name.Position = controlPos;
        name.HorizontalAlignment = 'left';
        
        valPos = controlPos + [controlPos(3) 0 0 0];
        if strcmp(regType,'logical') && isscalar(regV)
            h.regControls{end+1} = uicontrol('style','togglebutton','parent',h.panel2,'Callback',@callback_updateRegs);
            %             if strcmp('bypass',regN) || strcmp('Bypass',regN)
            %                 regV = 0;
            %             end
        else
            h.regControls{end+1} = uicontrol('style','edit','parent',h.panel2,'Callback',@callback_updateRegs);
            %             hexStrs = dec2hex(regV);
            %             strVal = hexStrs(1,:);
            %             for k = 2:size(hexStrs,1)
            %                 strVal = [strVal ' ' hexStrs(k,:)];
            %             end
            %             h.regControls{end}.String = strVal;
            h.regControls{end}.String = num2str(regV);
        end
        h.regControls{end}.Value = regV;
        h.regControls{end}.UserData = regN;
        h.regControls{end}.Position = valPos;
        
        controlPos(2) = controlPos(2) + controlPos(4);
    end
    uicontrol('style','text','string',blocksPart{j}.blockName,'parent',h.panel2,'Position',[controlPos(1) controlPos(2) controlPos(3)*2 controlPos(4)],'FontWeight','bold');
    controlPos(2) = controlPos(2) + controlPos(4);
end
h.panel2.Position(4) = controlPos(2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% create controls panel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pos_viewerBtn = [(pos_controls_panel(3)-90)/2-10 10 90 30];
pos_restBtn = pos_viewerBtn + [0 pos_viewerBtn(3)+10 0 0];
pos_inlargeBtn = pos_restBtn + [0 pos_restBtn(3)+150 0 0];
pos_saveBtn = pos_restBtn + [0 pos_restBtn(4)+5 0 0];
pos_loadBtn = pos_saveBtn + [0 pos_saveBtn(4)+5 0 0];
pos_printBtn = pos_loadBtn + [0 pos_saveBtn(4)+5 0 0];
pos_save_imagesBtn = pos_printBtn + [0 pos_printBtn(4) + 10 0 0];

pos_colorBar_cntr = [0 pos_controls_panel(4)*2/3 pos_controls_panel(3) pos_controls_panel(4)/3];
SUB_PANEL_H = pos_colorBar_cntr(4)/5;
pos_z = [0 pos_colorBar_cntr(4)-SUB_PANEL_H-20 pos_colorBar_cntr(3) SUB_PANEL_H];
pos_i = [0 pos_colorBar_cntr(4)-SUB_PANEL_H*2-20 pos_colorBar_cntr(3) SUB_PANEL_H];
pos_c = [0 pos_colorBar_cntr(4)-SUB_PANEL_H*3-20 pos_colorBar_cntr(3) SUB_PANEL_H];

h.controlsPanel = uipanel('Parent',h.f,'Units','pixels','Position',pos_controls_panel);
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_ivbinViewer,'String','IVBin Viewer','Position',pos_viewerBtn,'Units','pixels');
h.doT = uicontrol('Style','checkbox','Parent',h.controlsPanel,'String','T','Position',pos_viewerBtn+[(pos_viewerBtn(3)+3) 0 (-pos_viewerBtn(3)+30) 0],'Units','pixels');
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_restoreRegs,'String','Reset regs','Position',pos_restBtn,'Units','pixels');
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_saveRegs,'String','Save Config','Position',pos_saveBtn,'Units','pixels');
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_loadRegs,'String','Load Config','Position',pos_loadBtn,'Units','pixels');
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_printConfig,'String','Print Config','Position',pos_printBtn,'Units','pixels');
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_saveImages,'String','Save Out Images','Position',pos_save_imagesBtn,'Units','pixels');

uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_inlargeImages,'String','Enlarge Z','Position',pos_inlargeBtn,'Units','pixels','UserData','Z');
pos_inlargeBtn(2) = pos_inlargeBtn(2) + pos_inlargeBtn(4) + 5;
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_inlargeImages,'String','Enlarge IR','Position',pos_inlargeBtn,'Units','pixels','UserData','IR');
pos_inlargeBtn(2) = pos_inlargeBtn(2) + pos_inlargeBtn(4) + 5;
uicontrol('Style','pushbutton','Parent',h.controlsPanel,'Callback',@callback_inlargeImages,'String','Enlarge Conf','Position',pos_inlargeBtn,'Units','pixels','UserData','Confidence');

colorbar_cnt_panel = uipanel('Parent',h.controlsPanel,'Units','pixels','Position',pos_colorBar_cntr,'title','Dynamic Range');

strW = floor(pos_colorBar_cntr(3)/6);
valW = strW*2;
pos = [0 5 strW SUB_PANEL_H/2];

zCBPanel = uipanel('Parent',colorbar_cnt_panel,'Units','pixels','Position',pos_z,'title','Z');
uicontrol('style','text','Units','pixels','string','Min:','parent',zCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.z.min = uicontrol('style','edit','Units','pixels','parent',zCBPanel,'Position',pos,'Callback',@callback_updateMinZColor);
pos(1) = pos(1) + valW;
pos(3) = strW;
uicontrol('style','text','Units','pixels','string','Max:','parent',zCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.z.max = uicontrol('style','edit','Units','pixels','parent',zCBPanel,'Position',pos,'Callback',@callback_updateMaxZColor);

pos = [0 5 strW SUB_PANEL_H/2];
iCBPanel = uipanel('Parent',colorbar_cnt_panel,'Units','pixels','Position',pos_i,'title','IR');
uicontrol('style','text','Units','pixels','string','Min:','parent',iCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.i.min = uicontrol('style','edit','Units','pixels','parent',iCBPanel,'Position',pos,'Callback',@callback_updateMinIColor);
pos(1) = pos(1) + valW;
pos(3) = strW;
uicontrol('style','text','Units','pixels','string','Max:','parent',iCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.i.max = uicontrol('style','edit','Units','pixels','parent',iCBPanel,'Position',pos,'Callback',@callback_updateMaxIColor);

pos = [0 5 strW SUB_PANEL_H/2];
cCBPanel = uipanel('Parent',colorbar_cnt_panel,'Units','pixels','Position',pos_c,'title','Conf');
uicontrol('style','text','Units','pixels','string','Min:','parent',cCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.c.min = uicontrol('style','edit','Units','pixels','parent',cCBPanel,'Position',pos,'Callback',@callback_updateMinCColor);
pos(1) = pos(1) + valW;
pos(3) = strW;
uicontrol('style','text','Units','pixels','string','Max:','parent',cCBPanel,'Position',pos);
pos(1) = pos(1) + strW;
pos(3) = valW - 10;
h.edit.c.max = uicontrol('style','edit','Units','pixels','parent',cCBPanel,'Position',pos,'Callback',@callback_updateMaxCColor,'String',num2str(h.colorBarsVal.C(2)));


%add radio buttons
radioBtnPanel = uipanel('Parent',colorbar_cnt_panel,'Units','pixels','Position',[10 20 pos_controls_panel(3)-20 50],'title','Set By');
h.r1 = uicontrol('style','radiobutton','Units','pixels','parent',radioBtnPanel,'Position',[15 10 40 20],'String','in','Callback',@callback_radiobuttons,'Value',0);
h.r2 = uicontrol('style','radiobutton','Units','pixels','parent',radioBtnPanel,'Position',[70 10 40 20],'String','out','Callback',@callback_radiobuttons,'Value',1);

guidata(h.f,h);
runJFIL(h.f);

updateCBMinMax(h.f);
showImages(h.f,1);
updatColorMaps(h.f);
end

function callback_updateRegs(varargin)
h = guidata(varargin{1});

rN = varargin{1}.UserData;
if strcmp(varargin{1}.Style,'togglebutton')
    val = varargin{1}.Value;
else
    val = varargin{1}.String;
    if(isempty(val))%reset to default
        varargin{1}.String = num2str(h.defRegs.JFIL.(rN));
        val = h.defRegs.JFIL.(rN);
    else
        val = str2num(val);
    end
end


if h.regs.JFIL.(rN) == val
    return
end
h.regs.JFIL.(rN) = val;
varargin{1}.Value = val;
guidata(h.f,h);

runJFIL(h.f);

updateCBMinMax(varargin{1});
showImages(h.f);
updatColorMaps(h.f);
end

function callback_updatePanel2Pos(varargin)
h = guidata(varargin{1});
h.panel2.Position(2) = -varargin{1}.Value * (h.panel2.Position(4) - h.panel1.Position(4));
guidata(varargin{1},h);
end

function showImages(f,~)
h = guidata(f);
sp1 = subplot(1, 3, 1, 'Parent', h.input_images_panel);
imagesc(h.input.zImgRAW,[0 h.colorBarsVal.Z(2)]);
colorbar(sp1,'southoutside','Ticks',round([h.colorBarsVal.Z(1) round((h.colorBarsVal.Z(2)+h.colorBarsVal.Z(1))/2) h.colorBarsVal.Z(2)]))
title(sp1,'Z');

sp2 = subplot(1, 3, 2, 'Parent', h.input_images_panel);
imagesc(h.input.iImgRAW,[0 h.colorBarsVal.IR(2)]);
colorbar(sp2,'southoutside','Ticks',round([h.colorBarsVal.IR(1), round((h.colorBarsVal.IR(2)+h.colorBarsVal.IR(1))/2), h.colorBarsVal.IR(2)]))
title(sp2,'IR');

sp3 = subplot(1, 3, 3, 'Parent', h.input_images_panel);
imagesc(h.input.cImgRAW,[0 h.colorBarsVal.C(2)]);
colorbar(sp3,'southoutside','Ticks',round([h.colorBarsVal.C(1) round((h.colorBarsVal.C(2)+h.colorBarsVal.C(1))/2) h.colorBarsVal.C(2)]))
title(sp3,'Conf');


sp4 = subplot(1, 3, 1, 'Parent', h.output_images_panel);
imagesc(h.outputImages.zImgRAW,h.colorBarsVal.Z);
colorbar(sp4,'southoutside','Ticks',round([h.colorBarsVal.Z(1) round((h.colorBarsVal.Z(2)+h.colorBarsVal.Z(1))/2) h.colorBarsVal.Z(2)]))
title(sp4,'Z');

sp5 = subplot(1, 3, 2, 'Parent', h.output_images_panel);
colorbar('off')
imagesc(h.outputImages.iImgRAW,h.colorBarsVal.IR);
colorbar(sp5,'southoutside','Ticks',round([h.colorBarsVal.IR(1) round((h.colorBarsVal.IR(2)+h.colorBarsVal.IR(1))/2) h.colorBarsVal.IR(2)]))
title(sp5,'IR');

sp6 = subplot(1, 3, 3, 'Parent', h.output_images_panel);
colorbar('off')
imagesc(h.outputImages.cImgRAW,h.colorBarsVal.C);
colorbar(sp6,'southoutside','Ticks',round([h.colorBarsVal.C(1), round((h.colorBarsVal.C(2)+h.colorBarsVal.C(1))/2), h.colorBarsVal.C(2)]))
title(sp6,'Conf');

linkaxes([sp1 sp2 sp3 sp4 sp5 sp6]);
z = zoom(sp1);
z.ActionPostCallback = @callback_postZoom;

if nargin > 1
    h.images_zoom = get(gca,{'xlim','ylim'});
    
else
    set(sp1,{'xlim','ylim'},h.images_zoom);
end
%set(h.f,'windowscrollWheelFcn',@callback_windowscrollWheelFcn);
guidata(f,h);
end

function updatColorMaps(f)
h = guidata(f);
h.edit.z.min.String = num2str(round(h.colorBarsVal.Z(1)));
h.edit.z.max.String = num2str(round(h.colorBarsVal.Z(2)));
h.edit.i.min.String = num2str(round(h.colorBarsVal.IR(1)));
h.edit.i.max.String = num2str(round(h.colorBarsVal.IR(2)));
h.edit.c.min.String = num2str(round(h.colorBarsVal.C(1)));
h.edit.c.max.String = num2str(round(h.colorBarsVal.C(2)));
guidata(f,h);
end

function callback_postZoom(varargin)
h = guidata(varargin{1});
h.images_zoom = get(gca,{'xlim','ylim'});  % Get axes limits.
guidata(h.f,h);
end

function callback_updateMinZColor(varargin)
h=guidata(varargin{1});
h.colorBarsVal.Z(1) = str2double(varargin{1}.String);
guidata(h.f,h);
showImages(varargin{1});
end

function callback_updateMaxZColor(varargin)
h = guidata(varargin{1});
h.colorBarsVal.Z(2) = str2double(varargin{1}.String);
guidata(h.f,h);
showImages(varargin{1})
end

function callback_updateMinIColor(varargin)
h = guidata(varargin{1});
h.colorBarsVal.IR(1) = str2double(varargin{1}.String);
guidata(h.f,h);
showImages(varargin{1});
end

function callback_updateMaxIColor(varargin)
h = guidata(varargin{1});
h.colorBarsVal.IR(2) = str2double(varargin{1}.String);
guidata(varargin{1},h);
showImages(varargin{1})
end

function callback_updateMinCColor(varargin)
h = guidata(varargin{1});
h.colorBarsVal.C(1) = str2double(varargin{1}.String);
guidata(h.f,h);
showImages(varargin{1});
end

function callback_updateMaxCColor(varargin)
h = guidata(varargin{1});
h.colorBarsVal.C(2) = str2double(varargin{1}.String);
guidata(varargin{1},h);
showImages(varargin{1})
end

function callback_ivbinViewer(varargin)
h = guidata(varargin{1});
if h.doT.Value == 1
    ivbin_viewer(h.outputImages.zImgRAW',h.input.zImgRAW');
else
    ivbin_viewer(h.outputImages.zImgRAW,h.input.zImgRAW);
end
end

function callback_windowscrollWheelFcn(varargin)
h = guidata(varargin{1});
isRegPanelSon = 0;
obj = gco;
while obj ~= h.f
    obj = get(obj,'parent');
    if obj == h.panel1
        isRegPanelSon = 1;
        break;
    end
end
if isRegPanelSon == 1
    stepsN = varargin{2}.VerticalScrollCount;
    h.hsld.Value = h.hsld.Value - stepsN*h.hsld.SliderStep(1);
    if h.hsld.Value <= h.hsld.Min
        h.hsld.Value = h.hsld.Min;
    elseif h.hsld.Value >= h.hsld.Max
        h.hsld.Value = h.hsld.Max;
    end
    guidata(varargin{1},h);
    callback_updatePanel2Pos(h.hsld);
end
end

function callback_radiobuttons(varargin)
h = guidata(varargin{1});
if varargin{1} == h.r1
    h.r2.Value = 1 - h.r1.Value;
else
    h.r1.Value = 1 - h.r2.Value;
end
guidata(varargin{1},h);
updateCBMinMax(varargin{1});
showImages(varargin{1});
updatColorMaps(varargin{1});
end

function updateCBMinMax(f)
h = guidata(f);
if h.r2.Value == 1
    h.colorBarsVal.Z = [min(h.outputImages.zImgRAW(:)) max(h.outputImages.zImgRAW(:))];
    h.colorBarsVal.IR = [min(h.outputImages.iImgRAW(:)) max(h.outputImages.iImgRAW(:))];
    h.colorBarsVal.C = [min(h.outputImages.cImgRAW(:)) max(h.outputImages.cImgRAW(:))];
else
    h.colorBarsVal.Z = [min(h.input.zImgRAW(:)) max(h.input.zImgRAW(:))];
    h.colorBarsVal.IR = [min(h.input.iImgRAW(:)) max(h.input.iImgRAW(:))];
    h.colorBarsVal.C = [min(h.input.cImgRAW(:)) max(h.input.cImgRAW(:))];
end

if h.colorBarsVal.Z(1) == h.colorBarsVal.Z(2)
    h.colorBarsVal.Z(2) = h.colorBarsVal.Z(2) + 2;
end
if h.colorBarsVal.IR(1) == h.colorBarsVal.IR(2)
    h.colorBarsVal.IR(2) = h.colorBarsVal.IR(2) + 2;
end
if h.colorBarsVal.C(1) == h.colorBarsVal.C(2)
    h.colorBarsVal.C(2) = h.colorBarsVal.C(2) + 2;
end
guidata(f,h);
end

function [blocksPart] = BolcksRegsPatition(regNames)
JFILBlocksNames = {'inv' 'gamma' 'grad2' 'iFeatures' 'inn' 'dFeatures' 'dnn' 'bilt' 'edge4' 'sort1Edge03' 'edge3' 'sort3' 'upscale' 'geom' 'sort2' 'sort1Edge01' 'edge1' 'sort1' 'grad1'};
blocksPart = {};
generalIndexes = ones(length(regNames),1);
bypassIndx = contains(regNames,'bypass') | contains(regNames,'Bypass');
generalIndexes(bypassIndx) = 0;

for i = 1:length(JFILBlocksNames)
    blocksPart{end+1}.blockName = JFILBlocksNames(i);
    indexes = contains(regNames,JFILBlocksNames(i)) & generalIndexes == 1;
    generalIndexes(indexes) = 0;
    blocksPart{end}.regs = sort(regNames(indexes & ~bypassIndx));
    
end
blocksPart{end+1}.blockName = 'general';
blocksPart{end}.regs = sort(regNames(generalIndexes == 1));
blocksPart{end+1}.blockName = 'bypass';
blocksPart{end}.regs = regNames(bypassIndx);

end

function callback_restoreRegs(varargin)
h = guidata(varargin{1});
updateRegs(h.f,h.defRegs);
guidata(h.f,h);
end

function updateRegs(f,newRegs)
h = guidata(f);
isRegChanged = 0;

for i = 1:length(h.regControls)
    regN = h.regControls{i}.UserData;
    hregV = h.regs.JFIL.(regN);
    newV = newRegs.JFIL.(regN);
    if hregV ~= newV
        isRegChanged = 1;
        h.regs.JFIL.(regN) = newV;
        h.regControls{i}.Value = newV;
        if strcmp(h.regControls{i}.Style,'edit')
            h.regControls{i}.String = num2str(newV);
        end     
    end
end

if isRegChanged == 0
    return;
end
guidata(f,h);

runJFIL(h.f);

updateCBMinMax(f);
updatColorMaps(f);
showImages(f);
end

function sbar(src,callbackdata)

isCancelResize = 0;
h = guidata(src);

if isempty(h)
    return;
end

if h.f.Position(3) < h.MinSize(1)
    h.f.Position(3) = h.MinSize(1);
    isCancelResize = 1;
end
if h.f.Position(4) < h.MinSize(2)
    h.f.Position(4) = h.MinSize(2);
    isCancelResize = 1;
end
if isCancelResize ==1
    return;
end
yScale = h.f.Position(4)/h.lastPos(4);

h.controlsPanel.Position(4) = round(h.controlsPanel.Position(4) * yScale);
y_new_im_shift = round(h.output_images_panel.Position(4)* (yScale - 1));
h.output_images_panel.Position(4) = round(h.output_images_panel.Position(4) * yScale);
h.input_images_panel.Position(4) = round(h.input_images_panel.Position(4) * yScale);
h.input_images_panel.Position(2) = h.input_images_panel.Position(2) + y_new_im_shift;
h.images_panel.Position(4) = round(h.images_panel.Position(4) * yScale);
h.panel1.Position(4) = round(h.panel1.Position(4) * yScale);
h.hsld.Position(4) = h.hsld.Position(4) * yScale;

xInc = h.f.Position(3) - h.lastPos(3);

h.output_images_panel.Position(3) = h.output_images_panel.Position(3) + xInc;
h.input_images_panel.Position(3) = h.input_images_panel.Position(3) + xInc;
h.images_panel.Position(3) = h.images_panel.Position(3) + xInc;
h.controlsPanel.Position(1) = h.controlsPanel.Position(1) + xInc;

h.lastPos = h.f.Position;
guidata(src,h);
callback_updatePanel2Pos(h.hsld);
end

function callback_inlargeImages(varargin)
h = guidata(varargin{1});
imgs = {};
dRange = [];
if strcmp(varargin{1}.UserData,'Z')
    imgs = {h.input.zImgRAW h.outputImages.zImgRAW};
    dRange = h.colorBarsVal.Z;
elseif strcmp(varargin{1}.UserData,'IR')
    imgs = {h.input.iImgRAW h.outputImages.iImgRAW};
    dRange = h.colorBarsVal.IR;
elseif strcmp(varargin{1}.UserData,'Confidence')
    imgs = {h.input.cImgRAW h.outputImages.cImgRAW};
    dRange = h.colorBarsVal.C;
end
h.f = figure('numbertitle','off','name',varargin{1}.UserData);

sp1 = subplot(1,2,1);
imagesc(imgs{1},dRange);
title(sp1,'Input')

sp2 = subplot(1,2,2);
imagesc(imgs{2},dRange);
title(sp2,'Output')

linkaxes([sp1 sp2]);
%guidata(varargin{1},h);
end

function callback_saveRegs(varargin)
    h = guidata(varargin{1});
    regs = h.regs;
    d = datetime('now');
    sec = floor(d.Second);
    hund = round((d.Second - sec) * 100);
    regsFileName = ['regsConf_' num2str(d.Day) '_' num2str(d.Month) '_' num2str(d.Year) '_' num2str(d.Hour) '_' num2str(d.Minute) '_' num2str(sec) '_' num2str(hund) '.mat'];
    [file,path] = uiputfile('*.mat','Save Workspace As', regsFileName);
    save([path file],'regs');
end

function callback_saveImages(varargin)
h = guidata(varargin{1});
JFILRes = h.outputImages;
d = datetime('now');
sec = floor(d.Second);
hund = round((d.Second - sec) * 100);
regsFileName = ['JFILRes_' num2str(d.Day) '_' num2str(d.Month) '_' num2str(d.Year) '_' num2str(d.Hour) '_' num2str(d.Minute) '_' num2str(sec) '_' num2str(hund) '.mat'];
[file,path] = uiputfile('*.mat','Save Workspace As', regsFileName);
save([path file],'JFILRes');
end

function callback_loadRegs(varargin)
    h = guidata(varargin{1});
    [file,path] = uigetfile('*.mat','Load Regs Configuration');
    newRegs = load([path file],'regs');
    updateRegs(h.f,newRegs.regs);
    guidata(h.f,h);   
end

function runJFIL(f)
h = guidata(f);
hBox = msgbox('Running JFIL...', 'WindowStyle', 'modal');
hBox.Visible = 'off';
child = get(hBox,'Children');
delete(child(1))
centerfig(hBox,f)
hBox.Visible = 'on';
set_watches(h.f,false)
try
    [h.outputImages.zImgRAW, h.outputImages.iImgRAW, h.outputImages.cImgRAW, ~] = Pipe.JFIL.JFIL(h.input,h.regs,h.luts,Logger(),[]);
catch ME
    close(hBox);
    set_watches(h.f,true)
    error(ME.message)
    return;
end

guidata(f,h);
close(hBox);
set_watches(h.f,true)
end

function callback_printConfig(varargin)
    h = guidata(varargin{1});
    for i =length(h.regControls):-1:1
        rN = h.regControls{i}.UserData;
        msg = ['JFIL' rN ' = ' num2str(h.regs.JFIL.(rN))]; 
       disp(msg)
    end
end