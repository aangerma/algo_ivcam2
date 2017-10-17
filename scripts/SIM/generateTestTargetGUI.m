function generateTestTargetGUI

%%%%%%%%%%%%%%%%%%%%%%%%
%default sizes
%%%%%%%%%%%%%%%%%%%%%%%%
h.def_bg_margin = 10;
h.def_thickness = 40;
h.def_spacing = 50;
h.def_num_rows = 5; 
h.def_length_pole = 100;
h.def_bg_width = 10;
h.def_bg_distance = 100;
h.def_fiducial_reflectivity = 10; % [%]

%%%%%%%%%%%%%%%%%%%%%%%%
% main figure
%%%%%%%%%%%%%%%%%%%%%%%%
h.rowH = 20; %default size for rows and spacing of elements
h.winH = 1000;
h.winW = 900;
h.space = round(h.winW/100); % size for spacing between elements

h.f = figure('units','pixels','position',[0 0 h.winW h.winH],'menubar','none','toolbar','none','numberTitle','off',...
             'name','test target generator','resize','off');
centerfig(h.f);




%%%%%%%%%%%%%%%%%%%%%%%%%%
%radio buttons panel
%%%%%%%%%%%%%%%%%%%%%%%%%%

targetType = {'plane','grid','half sphere','cylinders','poles','random','wlgrid','CubesChart'};

%default target
h.target = 'plane';

%bg = button group
h.bgpW = h.space;
h.bgpH = h.winH-5*h.space;
h.bgW = h.winW-2*h.space;
h.bgH = 2*h.rowH;

h.bg = uibuttongroup('Visible','off','Parent',h.f,'title','choose target type:',...
                  'units','pixels','fontsize',10,...
                  'Position',[h.bgpW h.bgpH h.bgW h.bgH],...
                  'SelectionChangedFcn',@bselection);
              
% Create radio buttons in button group.
 for i = 1:length(targetType)
    h.button(i) = uicontrol('Style','radiobutton','Parent',h.bg,...
                          'String',targetType{i},...
                          'units','pixels','fontsize',10,...
                          'Position',[15+110*(i-1) 0 100 30],...
                          'HandleVisibility','off');
    h.button(i).Units = 'normalized';
    h.button(i).FontUnits = 'normalized';
 end

h.bg.Visible = 'on';






%%%%%%%%%%%%%%%%%%%%%%%%%%
%other options panel
%%%%%%%%%%%%%%%%%%%%%%%%%%

%oo == other options
h.oo = [];

%main oo panel
h.oo.panelpW = h.bgpW;
h.oo.panelpH = h.winH - 10.5*h.rowH;
h.oo.panelW = h.bgW;
h.oo.panelH = 8*h.rowH;


h.oo.ui_panel = uipanel('Parent',h.f,'title','choose other options for chosen target type:',...
    'units','pixels','fontsize',10,...
    'Position',[h.oo.panelpW h.oo.panelpH h.oo.panelW h.oo.panelH]);

%other otions implamantation

h.bg_margin = h.def_bg_margin;
h.bg_width = h.def_bg_width;
h.bg_distance = h.def_bg_distance;
h.thickness = h.def_thickness;
h.spacing = h.def_spacing;
h.num_rows = h.def_num_rows; 
h.length_pole = h.def_length_pole;

h.names = {'plane_margin','plane_width','plane_distance' , 'spacing', 'thickness' , 'num_rows', 'length_pole'};

default_sizes = [h.bg_margin,h.bg_width,h.bg_distance,h.spacing,h.thickness, h.num_rows ,h.length_pole]; %corespond to names
f_callback = {@plane_margin_callback; @plane_width_callback; @plane_distance_callback;...
              @spacing_callback; @thickness_callback;...
              @num_rows_callback; @length_pole_callback}; %corespond to names

for i = 1:length(h.names)
    h.oo.(h.names{i}) = [];
    h.oo.(h.names{i}).ui_panel = uipanel('Parent',h.oo.ui_panel,...
            'units','pixels','fontsize',10,'borderType','none',...
            'Position',[15 h.oo.panelH-(2*i+1)*h.rowH 200 2*h.rowH]);

    
    text = [];
    if( strcmp(h.names{i},'num_rows' ))
        text = 'num_rows(odd):';
    else 
        text = [h.names{i},':'];
    end
        
    h.oo.(h.names{i}).ui_text = uicontrol('Style','text','parent',h.oo.(h.names{i}).ui_panel,...
            'pos',[0 15 105 h.rowH],'string',text,...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',h.f.Color);
 
        
        
    h.oo.(h.names{i}).ui_edit = uicontrol('Style','edit','parent',h.oo.(h.names{i}).ui_panel,...
            'units','pixels','pos',[105 15 90 h.rowH],...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','string',num2str(default_sizes(i)),...
            'callback', f_callback{i}); 
	
    h.oo.(h.names{i}).ui_text.Units = 'normalized';
    h.oo.(h.names{i}).ui_text.FontUnits = 'normalized';        
    h.oo.(h.names{i}).ui_edit.Units = 'normalized';
    h.oo.(h.names{i}).ui_edit.FontUnits = 'normalized';
   
        
end


%vector checkbox
h.vectors = 'off';
h.oo.vectors_checkbox = uicontrol('style','checkbox','units','pixels','Parent',h.oo.ui_panel,...
                'horizontalAlignment','left','fontsize',10,...
                'position',[13,10,150,15],'string','show vectors','callback', @vectors_callback);
h.oo.vectors_checkbox.Units = 'normalized';
h.oo.vectors_checkbox.FontUnits = 'normalized';



%camera checkbox
h.camera = 'off';
h.oo.camera_checkbox = uicontrol('style','checkbox','units','pixels','Parent',h.oo.ui_panel,...
                'horizontalAlignment','left','fontsize',10,...
                'position',[130,10,150,15],'string','show camera place','callback', @camera_callback);
h.oo.camera_checkbox.Units = 'normalized';
h.oo.camera_checkbox.FontUnits = 'normalized';

   
%%%%%%%%%%%%%%%%%%
%fiducial panel
%%%%%%%%%%%%%%%%%%
h.fiducial = [];

h.fiducial.panelpW = h.bgpW;
h.fiducial.panelpH = h.winH - 12.5*h.rowH;
h.fiducial.panelW = h.bgW;
h.fiducial.panelH = 1.5*h.rowH;


h.fiducial.ui_panel = uipanel('Parent',h.f,...
    'units','pixels','fontsize',10,...
    'Position',[h.fiducial.panelpW h.fiducial.panelpH h.fiducial.panelW h.fiducial.panelH]);
    
h.fiducial.checkbox = uicontrol('style','checkbox','units','pixels','Parent',h.fiducial.ui_panel,...
                'horizontalAlignment','left','fontsize',10,'string','fiducial:','Value',0,...
                'position',[5,5,100,h.rowH],'callback', @checkbox_fiducial_callback);

h.fiducial.text = uicontrol('Style','text','parent',h.fiducial.ui_panel,'units','pixels',...
    'pos',[100,5,100,h.rowH],'horizontalAlignment','left','fontsize',10,'Enable','off',...
    'string','reflectivity [%]:');

h.fiducial.edit = uicontrol('Style','edit','parent',h.fiducial.ui_panel,'units','pixels','Enable','off',...
    'pos',[190,5,50,h.rowH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w',...
    'string',num2str(h.def_fiducial_reflectivity),'callback', @checkbox_fiducial_callback);

h.fiducial_reflectivity = -1;

h.fiducial.checkbox.Units = 'normalized';
h.fiducial.checkbox.FontUnits = 'normalized';
h.fiducial.text.Units = 'normalized';
h.fiducial.text.FontUnits = 'normalized';
h.fiducial.edit.Units = 'normalized';
h.fiducial.edit.FontUnits = 'normalized';



%%%%%%%%%%%%%%%%%%
%axes icons
%%%%%%%%%%%%%%%%%%

h.icons = [];
h.icons.ui_panel = uipanel('Parent',h.f,'units','pixels','fontsize',10,'Position',[10 670 30 77],'borderType','none');

%get icons
f= figure('Visible','off');
hToolbar = findall(gcf,'tag','FigureToolBar');
aaa=get(findall(hToolbar),'tag');

pan = findall(hToolbar,'tag',aaa{10});
panImg =imagesc(pan.CData);
panImg = panImg.CData;

zoom = findall(hToolbar,'tag',aaa{12});
zoomImg = imagesc(zoom.CData);
zoomImg = zoomImg.CData;

rot = findall(hToolbar,'tag',aaa{9});
rotImg = imagesc(rot.CData);
rotImg = rotImg.CData;

close(f);

h.icons.zoom_button = uicontrol('style','pushbutton','parent',h.icons.ui_panel,'units','pixels','pos',[1,1,25,25],'callback','zoom','cdata',zoomImg);
h.icons.zoom_button.Units = 'normalized';

h.icons.pan_button = uicontrol('style','pushbutton','parent',h.icons.ui_panel,'units','pixels','pos',[1,27,25,25],'callback','pan','cdata',panImg);
h.icons.pan_button.Units = 'normalized';


h.icons.rot_button = uicontrol('style','pushbutton','parent',h.icons.ui_panel,'units','pixels','pos',[1,53,25,25],'callback','rotate3d','cdata',rotImg);
h.icons.rot_button.Units = 'normalized';



%enable/disable default
h.target = 'plane';
oo_order();


%%%%%%%%%%%%%%%%%%%%%%%%%%
%axes
%%%%%%%%%%%%%%%%%%%%%%%%%%


h.axespW = 6*h.space;
h.axespH = 8*h.space;
h.axesW = h.winW- 4*h.space;
h.axesH = h.winH*0.65;

h.axes = axes('Units','pixels','Position',[h.axespW h.axespH h.axesW h.axesH],'Parent',h.f);

%default file output


%%%%%%%%%%%%%%%%%%%%%%%%%%
%save
%%%%%%%%%%%%%%%%%%%%%%%%%%

h.save_butoon_ui = uicontrol('style','pushbutton','parent',h.f,'units','pixels',...
        'pos',[ h.winW/2-25 10 50 h.rowH],'horizontalAlignment','center','fontsize',10,'FontWeight','bold',....
        'backgroundcolor','green','callback',@callback_saveFile,'string','save');


    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%default plot to begin with
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generator();   
    



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%normalized components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h.f.Units = 'normalized';
h.axes.Units = 'normalized';
h.save_butoon_ui.Units = 'normalized';
h.save_butoon_ui.FontUnits = 'normalized';
h.oo.ui_panel.Units = 'normalized';
h.oo.ui_panel.FontUnits = 'normalized';
h.oo.ui_panel.Units = 'normalized';
h.oo.ui_panel.FontUnits = 'normalized';
h.fiducial.ui_panel.Units = 'normalized';
h.icons.ui_panel.Units = 'normalized';
h.bg.Units = 'normalized';
h.bg.FontUnits = 'normalized';
for i=1:length(h.names)
    h.oo.(h.names{i}).ui_panel.Units = 'normalized';
end
% Move the window to the center of the screen.
movegui(h.f,'center');

h.f.Resize = 'on';








%%%%%%%%%%%%%%%%%%%%%%%%%%
%callbeck funcs
%%%%%%%%%%%%%%%%%%%%%%%%%%


function bselection(source,callbackdata)
    
    if( strcmp('half sphere',h.bg.SelectedObject.String) )
        h.target ='hsphere';
    else
        h.target = h.bg.SelectedObject.String;
    end
    
    oo_order();
    
    set(h.f, 'pointer', 'watch');
    drawnow;
    generator();
    set(h.f, 'pointer', 'arrow');
    
end

function oo_order()

    for j=1:length(h.names)
        h.oo.(h.names{j}).ui_panel.Units = 'pixels';
    end

    h.oo.plane_margin.ui_panel.Position = [15 h.oo.panelH-7*h.rowH 200 2*h.rowH];
    h.oo.plane_width.ui_panel.Position = [15 h.oo.panelH-5*h.rowH 200 2*h.rowH];
    h.oo.plane_distance.ui_panel.Position = [15 h.oo.panelH-3*h.rowH 200 2*h.rowH];
    h.oo.plane_margin.ui_panel.Visible = 'on';
    h.oo.plane_width.ui_panel.Visible = 'on';
    h.oo.plane_distance.ui_panel.Visible = 'on';
    
    if ( strcmp(h.target, 'random') || strcmp(h.target, 'plane') ) 
        h.oo.spacing.ui_panel.Visible = 'off';
        h.oo.thickness.ui_panel.Visible = 'off';
        h.oo.num_rows.ui_panel.Visible = 'off';
        h.oo.length_pole.ui_panel.Visible = 'off';
    elseif ( strcmp(h.target, 'poles'))
        h.oo.thickness.ui_panel.Position = [15+300 h.oo.panelH-3*h.rowH 200 2*h.rowH];
        h.oo.num_rows.ui_panel.Position = [15+300 h.oo.panelH-5*h.rowH 200 2*h.rowH];
        h.oo.spacing.ui_panel.Position = [15+300 h.oo.panelH-7*h.rowH 200 2*h.rowH];
        h.oo.length_pole.ui_panel.Position = [15+2*300 h.oo.panelH-3*h.rowH 200 2*h.rowH];
        h.oo.length_pole.ui_panel.Visible = 'on';
        h.oo.thickness.ui_panel.Visible = 'on';
        h.oo.num_rows.ui_panel.Visible = 'on';
        h.oo.spacing.ui_panel.Visible = 'on';
    elseif ( strcmp(h.target, 'grid'))
        h.oo.thickness.ui_panel.Position = [15+300 h.oo.panelH-3*h.rowH 200 2*h.rowH];
        h.oo.spacing.ui_panel.Visible = 'off';
        h.oo.thickness.ui_panel.Visible = 'on';
        h.oo.num_rows.ui_panel.Visible = 'off';
        h.oo.length_pole.ui_panel.Visible = 'off';
    elseif ( strcmp(h.target, 'cylinders'))
        h.oo.thickness.ui_panel.Position = [15+300 h.oo.panelH-3*h.rowH 200 2*h.rowH];
        h.oo.num_rows.ui_panel.Position = [15+300 h.oo.panelH-5*h.rowH 200 2*h.rowH];
        h.oo.spacing.ui_panel.Position = [15+300 h.oo.panelH-7*h.rowH 200 2*h.rowH];       
        h.oo.spacing.ui_panel.Visible = 'on';
        h.oo.thickness.ui_panel.Visible = 'on';
        h.oo.num_rows.ui_panel.Visible = 'on';
        h.oo.length_pole.ui_panel.Visible = 'off';
    elseif ( strcmp(h.target, 'wlgrid'))
        h.oo.thickness.ui_panel.Position = [15+300 h.oo.panelH-3*h.rowH 200 2*h.rowH];
        h.oo.num_rows.ui_panel.Position = [15+300 h.oo.panelH-5*h.rowH 200 2*h.rowH];  
        h.oo.spacing.ui_panel.Visible = 'off';
        h.oo.thickness.ui_panel.Visible = 'on';
        h.oo.num_rows.ui_panel.Visible = 'on';
        h.oo.length_pole.ui_panel.Visible = 'off';
    elseif (strcmp(h.target, 'CubesChart'))
        h.oo.plane_width.ui_panel.Visible = 'off';
        h.oo.plane_margin.ui_panel.Visible = 'off';
        h.oo.spacing.ui_panel.Visible = 'off';
        h.oo.thickness.ui_panel.Visible = 'off';
        h.oo.num_rows.ui_panel.Visible = 'off';
        h.oo.length_pole.ui_panel.Visible = 'off';
    end
    
    
    for j=1:length(h.names)
        h.oo.(h.names{j}).ui_panel.Units = 'normalized';
    end

end


function plane_margin_callback(source,callbackdata)

    h.bg_margin =  str2double(source.String);
    if( isnan(h.bg_margin) || h.bg_margin <=0 )
        source.String = num2str(h.def_bg_margin);
        h.bg_margin = h.def_bg_margin;
    end
        
    generator();
end

function plane_width_callback(source,callbackdata)

    h.bg_width =  str2double(source.String);
    if( isnan(h.bg_width) || h.bg_width <=0 )
        source.String = num2str(h.def_bg_width);
        h.bg_width = h.def_bg_width;
    end
        
    generator();
end

function plane_distance_callback(source,callbackdata)

    h.bg_distance =  str2double(source.String);
    if( isnan(h.bg_distance) || h.bg_distance <=0 )
        source.String = num2str(h.def_bg_distance);
        h.bg_distance = h.def_bg_distance;
    end
        
    generator();
end

function spacing_callback(source,callbackdata)
    h.spacing =  str2double(source.String);
    if( isnan(h.spacing) || h.spacing <=0 )
        source.String = num2str(h.def_spacing);
        h.spacing = h.def_spacing;
%     elseif( h.spacing > h.bg_margin )
%         source.String = num2str(h.bg_margin-1);
%         h.spacing = h.bg_margin-1;   
    end
    generator();
end

function thickness_callback(source,callbackdata)
    h.thickness =  str2double(source.String);
    if( isnan(h.thickness) || h.thickness <=0 || h.thickness >=100)
        source.String = num2str(h.def_thickness);
        h.thickness = h.def_thickness;
    end
    generator();
end

function num_rows_callback(source,callbackdata)
    h.num_rows = str2double(source.String);
    if( isnan(h.num_rows) || h.num_rows <=0 )
        source.String = num2str(h.def_num_rows);
        h.num_rows = h.def_num_rows;
    end
    if( mod(h.num_rows,2) == 0 )
        h.num_rows = h.num_rows+1;
        source.String = num2str(h.num_rows);
    end
    generator();
end

function length_pole_callback(source,callbackdata)
    h.length_pole =  str2double(source.String);
    if( isnan(h.length_pole) || h.length_pole <=0 )
        source.String = num2str(h.def_length_pole);
        h.length_pole = h.def_length_pole;
    end
    generator();
end


 function vectors_callback(source,callbackdata)
    if(source.Value == 1)
        h.vectors = 'on';
    else
        h.vectors = 'off';
    end
       
    generator();
 end


 function camera_callback(source,callbackdata)
    if(source.Value == 1)
        h.camera = 'on';
    else
        h.camera = 'off';
    end

    generator();
 end




%save file butoon
function callback_saveFile(source,callbackdata)
[f,d]=uiputfile('*.stl','Save As...');

    if(d~=0)
        generateTestTarget(h.target,h.bg_margin,h.bg_width,h.bg_distance,'thickness',h.thickness,...
        'outfn',[d,f],'vectors',h.vectors,'camera',h.camera,...
        'dist',h.spacing,'Num', h.num_rows , 'length_pole', h.length_pole,...
        'axes_handle', h.axes);
    end
end

%fiducial checkbox
function checkbox_fiducial_callback(source,callbackdata)
    if(h.fiducial.checkbox.Value == 1)
        h.fiducial.text.Enable = 'on';
        h.fiducial.edit.Enable = 'on';
        
        fidu_num = str2double(h.fiducial.edit.String);
        if( isnan(fidu_num) || fidu_num <0 || fidu_num>100 )
            h.fiducial.edit.String = num2str(h.def_fiducial_reflectivity);
            fidu_num = h.def_fiducial_reflectivity;
        end
        
        
        
        h.fiducial_reflectivity = fidu_num;
        
    else
        h.fiducial.text.Enable = 'off';
        h.fiducial.edit.Enable = 'off';
        h.fiducial_reflectivity = -1;
    end
    
    generator();
 end



%generator of targets
function generator()

    generateTestTarget(h.target,h.bg_margin,h.bg_width,h.bg_distance,'thickness',h.thickness,...
    'outfn',[],'vectors',h.vectors,'camera',h.camera,...
    'dist',h.spacing,'Num', h.num_rows , 'length_pole', h.length_pole,...
    'axes_handle', h.axes, 'fiducial', h.fiducial_reflectivity);
end









end


