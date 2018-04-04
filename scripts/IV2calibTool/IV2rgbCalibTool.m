function IV2rgbCalibTool
W=500;
H=220;
lh=22;
h.f = figure('name','POC4 rangeFinder','numbertitle','off','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);
uicontrol('style','pushbutton','units','pixels','position',[10 10 W-20 lh],'String','START','parent',h.f,'callback',@callback_run);

guidata(h.f,h);
end

function callback_run(varargin)
    h=guidata(varargin{1});
end