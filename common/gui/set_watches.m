%set_watches
%recusivly enables/disables all uicontrol object that are not text,and
%changes the mouse pointer occording
%syntax: set_watches([figure_handle],[BOOL])
%example:
%set_watches(h.f,false,{'pushbutton', 'slider'}); - will only mask
%pushbuttons and sliders
function set_watches(fig_handle,mode,only_ui_type)
if( nargin == 2 )
    only_ui_type = [];
end

modeString = 'off';
ptr='watch';
if mode
    modeString='on';
    ptr='arrow';
end

set(fig_handle,'pointer',ptr);
rec_set(fig_handle,modeString,only_ui_type)
pause(0.1);
end

function rec_set(fig_handle,mode,only_ui_type)
if(~isempty(get(fig_handle,'Children')))
    childs=get(fig_handle,'Children');
    for i=1:length(childs)
        rec_set(childs(i),mode,only_ui_type)
    end
else
    if(strcmp(get(fig_handle,'Type'),'uicontrol') &&sum(strcmp(get(fig_handle,'Style'),{'text'}))==0)
        if( isempty(only_ui_type) )
            set(fig_handle,'Enable',mode)
        else
            if( sum(strcmp(fig_handle.Style,only_ui_type)) > 0 )
                set(fig_handle,'Enable',mode);
            end
        end
    end
end
end
