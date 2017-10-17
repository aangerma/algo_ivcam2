function displayVolumeSliceGUI(varargin)
% close all

fh = figure('name','VolumeSliceGUI','NumberTitle','off','menubar','none','toolBar','figure');
h = guidata(fh);

if(nargin==0)
    vars = evalin('base','who');
    a=cellfun(@(x) evalin('base',['length(size(' x '))']),vars);
    vars = vars(a==3);
    
    
     if(length(vars)~=1)
         v=listdlg('PromptString','Select volume','SelectionMode','single','ListString',vars);
         
     else
         v = 1;
     end
         h.vol = evalin('base',vars{v});
else
    if(ischar(varargin{1}))
        h.vol = loadModel(varargin{1});
    elseif(length(size(varargin{1}))==3)
        h.vol=varargin{1};
    else
        error('unknonwn input');
    end
end
h.vol = double(h.vol);
h.minmax = [min(h.vol(:)) eps+max(h.vol(:))];
h.funcvargin=varargin(2:end);

guidata(fh,h);
%draw


h.a = axes('parent',fh);
guidata(fh,h);
h.xyz = zeros(4,1);
h.xyz(4) = uibuttongroup('parent',fh,'BorderType','none','SelectionChangeFcn',@dimChange);
h.xyz(3)=uicontrol('Style','radio','parent',h.xyz(4),'string','Z','units','normalized','position',[ 2/3 0 1/3 1]);
h.xyz(2)=uicontrol('Style','radio','parent',h.xyz(4),'string','X','units','normalized','position',[ 1/3 0 1/3 1]);
h.xyz(1)=uicontrol('Style','radio','parent',h.xyz(4),'string','Y','units','normalized','position',[ 0/3 0 1/3 1]);
h.sliderB = uicontrol('style','slider','parent',fh,'callback',@sliderUpdateAxes,'value',.5);

guidata(fh,h);

updateGUI(fh);
updateAxes(fh);
  addlistener(h.sliderB,'Value','PostSet',@(s,e)sliderUpdateAxes(fh));
set(fh,'ResizeFcn',@updateGUI);
set(fh,'WindowScrollWheelFcn',@winScroll_callback);
end

function winScroll_callback(varargin)
h=guidata(varargin{1});
indx = get(h.sliderB,'value');
indx = indx - varargin{2}.VerticalScrollCount;
set(h.sliderB,'value',indx);
updateAxes(varargin{1});
end
function sliderUpdateAxes(varargin)
h = guidata(varargin{1});
xyl=get(h.a,{'xlim','ylim'});
updateAxes(varargin{1});
set(h.a,{'xlim','ylim'},xyl);
end
function updateGUI(varargin)
fh = varargin{1};

hh = guidata(fh);
p = get(fh,'pos');
w = p(3);
h = p(4);
scrollBarH = 20;
xyzToggleWidth = 125;
set(hh.a,'units','pixels','OuterPosition',[0 scrollBarH,w h-scrollBarH]);
set(hh.xyz(4),'units','pixels','pos',[0 0,xyzToggleWidth scrollBarH]);
set(hh.sliderB,'units','pixels','pos',[xyzToggleWidth 0,w-xyzToggleWidth scrollBarH]);



% set(h.a,'units','pixels','pos',[20 H+40,p(3)-20 p(4)-H-60]);
% set(h.xyz(4),'units','pixels','pos',[0 0,RW*3+5 H]);
% set(h.sliderB,'units','pixels','pos',[RW*3+5 0,p(3)-RW*3-5 H],'value',.5);
% set(h.sliderR,'units','pixels','pos',[RW*3+5 0, H],'value',.5);
guidata(fh,hh);
dimChange(fh)
end

function dimChange(varargin)
h = guidata(varargin{1});
dim = find(get(h.xyz(4),'selectedObject')==h.xyz);
dimSize = size(h.vol,dim);
oldv = get(h.sliderB,'value');
newv = min(max(1,oldv/(get(h.sliderB,'max')-get(h.sliderB,'min'))*(dimSize-1)+1),dimSize);
set(h.sliderB,'min',1,'max',dimSize,'SliderStep',[1 1]/(dimSize-1),'value',newv);
guidata(varargin{1},h);
updateAxes(varargin{1});

end

function updateAxes(varargin)
h = guidata(varargin{1});
indx = get(h.sliderB,'value');
indx = round(indx);
dim = find(get(h.xyz(4),'selectedObject')==h.xyz);

switch(dim)
    case 1
        img = permute(h.vol(indx,:,:),[3 2 1]);
        imagesc(img,'parent',h.a,h.funcvargin{:});
         xlabel('z');
         ylabel('x');

    case 2
        img = permute(h.vol(:,indx,:),[3 1 2]);
        imagesc(img,'parent',h.a,h.funcvargin{:});
        xlabel('z');
        ylabel('y');
    case 3
        img = h.vol(:,:,indx);
        imagesc(img,'parent',h.a,h.funcvargin{:});
        xlabel('x');
       ylabel('y');

end
axis image
set(get(h.a,'title'),'string',sprintf('%4d',indx));
% set(h.a,'clim',h.minmax);
 colorbar('peer',h.a)
end