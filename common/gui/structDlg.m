function s_fin = structDlg(s, varargin)

 %[s units]=xml2structWrapper('D:\Yoni\structDLG_files\params_860SKU1_indoor.xml','units');
 %structDlg(s, units);
 
s_units = initialize_s_units(s);
if(nargin == 2) 
    s_units = varargin{1};   
end

s_tmp = s;
close_flag=0;

SAVE_BUTTON_HEIGHT = 30;


% create the figure, and 2 panels - parent and child
p0 = [550 250 570 500];
f = figure('menubar','none','toolbar','none','resize','off','numbertitle','off','name','Struct dialog',...
    'Position',p0,'WindowScrollWheelFcn',@figScroll,'CloseRequestFcn', @close_req_callback); 

panel1 = uipanel('Parent',f,'Units','pixels','borderType','none');
panel2 = uipanel('Parent',panel1,'Units','pixels','borderType','none'); 

 p1=[0 0 p0(3) p0(4)];



p2=[ 0 -0.5*p0(4) p0(3)-20 2*p0(4)];
set(panel2,'Position', p2); % the position is relative to the parent (not width and height)
 

% draw the fields of the struct
handles = struct; % a struct of the uicontrol handles of each field in the original struct
[handles,h,hndl] = structWin(s,s_units,'',panel2,p2(4),0,0,handles); 

% update positions after the struct was already drawn
p2(4) = h+SAVE_BUTTON_HEIGHT+5+10;
if (p2(4) < p0(4)) 
    p0(4) = p2(4); % reduce the figure height
    p0(3) = p0(3) - 20; % reduce the figure width
    p0(2) = p0(2)+(400-h); % lift the figure
end


p2(2) = p0(4)-h-40; % update the height of panel2 according to the struct length (h)

set(panel2,'Position',p2);
set(f,'Position',p0);
set(panel1,'Position',p1);
set(hndl,'position',[2 SAVE_BUTTON_HEIGHT+5 p2(3)-4,h]);

% add the SAVE button
uicontrol('Style','Pushbutton','Units','Pixels','Position',[5 5 p2(3)-10 SAVE_BUTTON_HEIGHT],'ForegroundColor','r','FontWeight','bold','String','SAVE','Parent',panel2,'callback','uiresume'); 

% create the scroller
gui_dat.p0 = p0;
gui_dat.h = h;
guidata(panel2,gui_dat);
sliderstep = p1(4) / (p2(4) - p1(4));  %  visible length /(total length - visible length)
if ( p2(4) > p0(4)) % only if the struct is long enough
    hslider = uicontrol('Style','Slider','Parent',f,... 
        'Units','Pixels','Position',[p0(3)-20 0 20 p0(4)],...  
        'Value',1,'SliderStep',[0.01,sliderstep],'Callback',{@slider_callback,panel2});
        addlistener(hslider,'Value','PostSet',@(s,e)slider_callback(hslider,'',panel2)); % makes the scrolling movement continuous
        % callback - reacts when the user interacts with the uicontrol
        % the second arguement (panel2) is the input arg (arg1) of the slider_callback1
end

% copy the struct  
uiwait;  % wait until uiresume is triggered - by pressing the save button
if(close_flag==0)
    s_fin = struct;  
   % if (isvalid(f)) % make sure the figure exists
       s_fin = copyStruct(s,0,handles); 
       % s_fin = s;
        delete(f);
end


function figScroll(src,callbackdata)
    
    if ( p2(4) > p0(4)) % only if the struct is long enough
        step = 0.2;
        if callbackdata.VerticalScrollCount > 0 
            if(hslider.Value-step>=0)
                hslider.Value = hslider.Value-step;
                
                arg1 = panel2;
                data = guidata(arg1);
                p0 = data.p0;
                h = data.h;
             
                pos = arg1.Position;
                arg1.Position =[0 hslider.Value*(p0(4)-h-20) pos(3) pos(4)];
                
            end
        elseif callbackdata.VerticalScrollCount < 0 
            if(hslider.Value+step<=1) 
                hslider.Value = hslider.Value+step;
                
                    arg1 = panel2;
                data = guidata(arg1);
                p0 = data.p0;
                h = data.h;
             
                pos = arg1.Position;
                arg1.Position =[0 hslider.Value*(p0(4)-h-20) pos(3) pos(4)];
                
                
                
            end
        end
    end
end % figScroll

%close without saving
function close_req_callback(src,callbackdata) 
%     if (isvalid(f)) % make sure the figure exists
        s_fin = s_tmp;
        close_flag=1;
        delete(f);
%     end  
end


end


function [handles,h,hndl,idx_out] = structWin(s,s_units,sname,phndl,ph,lvl,idx_in,handles)
% print all the fields of the struct recurssively.

idx_out = idx_in;
ROW_HEIGHT=20;
TAB_WIDTH = 30;
LETTER_WIDTH = 7;
p=get(phndl,'Position');
w = p(3);
n = getlen(s);
h=(n+1.5)*ROW_HEIGHT;
hndl = uipanel('Units','Pixels','Position',[2+TAB_WIDTH*lvl ph-h-2 w-4-TAB_WIDTH*lvl h-4],'Title',sname,'Parent',phndl,'borderType','none'); 


f = fieldnames(s);
TXT_LEN = cellfun(@(x) length(x),f)*LETTER_WIDTH;
UNIT_LEN = structfun(@(x) iff( ~isstruct(x), iff(~isempty(x),length(x)+3,0),0)  ,s_units)*LETTER_WIDTH;%+3 for the ' []'
TXT_LEN = max(TXT_LEN+UNIT_LEN);

ch = h-ROW_HEIGHT;
for i=1:length(f)
    if(isstruct(s.(f{i})))
        %%% recurssive call
        [handles,hi,~,idx_out] = structWin(s.(f{i}),s_units.(f{i}),f{i},hndl,ch,1,idx_out,handles);
        ch = ch-hi;
    else
        idx_out = idx_out+1;
        
        %units string addition
        units = [];
        if(~isempty(s_units.(f{i})))
            units = [  ' [' s_units.(f{i}) ']'  ];
        end
        %
        
        uicontrol('Style','Text','Units','Pixels','Position',[15 ch-ROW_HEIGHT TXT_LEN+5 ROW_HEIGHT],'String',[f{i} units],'Parent',hndl,'Horizontalalignment','Left'); 
        handles.(strcat('s',num2str(idx_out))) = uicontrol('Style','Edit','Units','Pixels','Position',[20+TXT_LEN ch-ROW_HEIGHT w-TXT_LEN-100 ROW_HEIGHT],'String',num2str(s.(f{i})),'Parent',hndl,'Horizontalalignment','Left','userData',class(s.(f{i})));       
        ch = ch-ROW_HEIGHT;
    end
end
h=h+0.5*ROW_HEIGHT;
end


function n = getlen(s)
n = 0;
f = fieldnames(s);
for i=1:length(f)
    if(isstruct(s.(f{i})))
        n = n + getlen(s.(f{i}));
        n = n + 2;
    else
        n = n + 1;
    end
end
end


function [s_fin,idx_out] = copyStruct(s,idx_in,handles)
% copy all the fields of the original struct (s) recurssively to the new
% struct (s_fin)

fn = fieldnames(s);
idx_out = idx_in;

for i=1:length(fn)
    if(isstruct(s.(fn{i})))
        [s_fin.(fn{i}),idx_out] = copyStruct(s.(fn{i}),idx_out,handles);
    else
        idx_out = idx_out+1;
        valStr = get(handles.(strcat('s',num2str(idx_out))),'String'); 
        valType = get(handles.(strcat('s',num2str(idx_out))),'userData');
        
        if(strcmp(valType,'char'))
            s_fin.(fn{i}) = valStr;
        else
            c = strsplit(valStr,' ');
            s_fin.(fn{i}) = cast(str2double(c),valType);
        end
    end
end

end


function slider_callback(varargin)
% src = The object that has focus when the user presses the key -
%       (automatic): UIControl - the slider
% eventdata = The action that caused the callback function to execute -
%             (automatic): ActionData varargin{2}
% arg1 = Panel (the panel2 in {@slider_callback1,panel2} )

src = varargin{1};
arg1 = varargin{3};
data = guidata(arg1);
p0 = data.p0;
h = data.h;
val = src.Value;
pos = arg1.Position;
arg1.Position =[0 val*(p0(4)-h-20) pos(3) pos(4)]; % position: [left bottom width height]
end


% initializing empty struct for s_units- if tis capability isn't in use
function s_units = initialize_s_units(s)
    f = fieldnames(s);
    for i=1:length(f)
        if(isstruct(s.(f{i})))
            s_units.(f{i}) = initialize_s_units(s.(f{i}));
        else
            s_units.(f{i}) = [];          
        end
    end            
end
