function IRViewer()
    %  mcc -m IRViewer.m -d  \\ger.corp.intel.com\ec\proj\ha\sa\SA_3DCam\ohad\share\IRviwer\
    % mcc -m IRViewer.m -d \\invcam322\ohad\share\irviewer
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % main panels
    %%%%%%%s%%%%%%%%%%%%%%%%%%%%%%%%%%%
    WIN_H = 650;
    WIN_W = 1800;
    
    
    
    h.f = figure('units','pixels','menubar','none','pos',[0 0 WIN_W WIN_H],...
        'toolbar','figure','numberTitle','off','name','IR Viewer');
    createGUI(h.f);
    h= guidata(h.f);
    centerfig(h.f);
    
    atoolbar=findall(findall(h.f,'tag','FigureToolBar'));
    tags = get(atoolbar,'tag');
    saveIndx = cellfun(@(x) ~isempty(x),strfind(tags,'SaveFigure'));
    loadIndx = cellfun(@(x) ~isempty(x),strfind(tags,'FileOpen'));
    printIndx = cellfun(@(x) ~isempty(x),strfind(tags,'PrintFigure'));
    set(atoolbar(saveIndx),'ClickedCallback',@callback_save);
    set(atoolbar(loadIndx),'ClickedCallback',@callback_load_from_file);
    set(atoolbar(printIndx),'ClickedCallback',@callback_print);
    
    
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'PlottoolsOn'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'PlottoolsOff'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'InsertLegend'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'InsertColorbar'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'Linking'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'Brushing'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'Rotate'))));
    delete(atoolbar(cellfun(@(x) ~isempty(x),strfind(tags,'NewFigure'))));
    
    
    
    % h.t_acc=[];
    h.xy = [];%%%%%%%%%
    h.plotHandles =[];
    h.snrTextH = [];
    
    
    
    guidata(h.f,h);
    % createGUI(h.f);
    h.GUI.hImg_ax.Visible='off';
    h.GUI.hFilter.Visible='on';
end

function callback_print(varargin)
    h= guidata(varargin{1});
    [d,f,~]=fileparts(h.GUI.input_file.String);
    %
    % [f,d]=uiputfile('*.png','Select file');
    % if(f==0)
    %     return;
    % end
    fn = fullfile(d,f);
    
    
    h=guidata(varargin{1});
    
    % imgData = uint8((h.DATA.vg-h.GUI.caxis_low.Value)/(h.GUI.caxis_high.Value-h.GUI.caxis_low.Value)*255);
    imgH = findobj(h.GUI.hImg_ax.Children,'type','image');
    imgData = imgH(1).CData;
    if(max(imgData(:))<1)
        imgData = uint16(normByMax(imgData)*(2^16-1));
    else
        imgData = uint16(imgData);
    end
    


    
    imwrite(imgData,[fn '.tif']);
    io.writeBin([fn '.bini'],imgData);
 
end

function callback_load_from_file(varargin)
    h= guidata(varargin{1});
    [f,d]=uigetfile('*.irviewer','Select file');
    if(f==0)
        return;
    end
    fn = [d,f];
    setWatches(h,false);
    h.DATA=load(fn,'-mat');
    h.GUI.load_data.BackgroundColor = 'g';
    setWatches(h,true);
    imageDisplay(h);
    
    h.GUI.hImg_ax.Visible='on';
    h.GUI.hFilter.Visible='on';
    h.loaded_tblXY = h.GUI.hTblXY.UserData{h.GUI.hTblXY.Value};
    h.loaded_input = h.GUI.input_file.String;
    guidata(h.f,h);
end


function callback_save(varargin)
    h= guidata(varargin{1});
    
    [f,d]=uiputfile('*.irviewer','Select file');
    if(f==0)
        return;
    end
    fn = [d,f];
    data = h.DATA;%#ok
    setWatches(h,false);
    save(fn,'-struct','data','-v7.3');
    setWatches(h,true);
end


function createGUI(varargin)
    
    DEF_FN_IN = '\\invcam322\ohad\data\lidar\EXP\20160502\26\1000_BRK13_40_300_137_calib.h5';
    DEF_ASIC_IN = '\\invcam322\Ohad\data\lidar\simulatorParams\slowChannel\slowChanSimParams.xml';
    
    
    h= guidata(varargin{1});
    
    ROW_H = 20;
    
    
    RCL_W = 770;
    LCL_W = 300;
    MRGN=3;
    txtW = 65;
    editW = 30;
    
    p = get(varargin{1},'pos');
    psz = p(3:4);
    
    mclW = max(0,psz(1)-RCL_W-LCL_W-2*MRGN);
    %%left column
    posInput = [MRGN   MRGN+psz(2)-10*ROW_H+6*ROW_H   LCL_W   4*ROW_H];
    posDataPlot = [MRGN  MRGN LCL_W 100+2*ROW_H];
    posFilters = [MRGN  posDataPlot(2)+posDataPlot(4)+5    LCL_W   psz(2)-2*MRGN-posInput(4)-posDataPlot(4)];
    posImg = [2*MRGN+LCL_W   MRGN   mclW   psz(2)-2*MRGN];
    posVaxes = [3*MRGN+LCL_W+mclW+50   MRGN+50          RCL_W-60   (psz(2)-2*MRGN)*0.75-50];
    posTable = [3*MRGN+LCL_W+mclW MRGN+posVaxes(4)+50 RCL_W (psz(2)-2*MRGN)*0.25];
    pos_Img_ax = [40 85 posImg(3)-50 posImg(4)-85];
    pos_caxis_low = [40 60 posImg(3)-50 20];
    pos_caxis_high = [40 35 posImg(3)-50 20];
    pos_export_fig = [40 10 posImg(3)-50 20];
    
    %for resizing figure
    if(~isempty(h))
        set(h.GUI.hImage,'pos',posImg);
        set(h.GUI.hFilter,'pos',posFilters);
        set(h.GUI.hInp,'pos',posInput);
        set(h.GUI.hVax,'pos',posVaxes);
        set(h.GUI.hTbl,'pos',posTable);
        h.GUI.hImg_ax.Position = pos_Img_ax;
        h.GUI.caxis_low.Position = pos_caxis_low;
        h.GUI.caxis_high.Position = pos_caxis_high;
        h.GUI.export_fig.Position =  pos_export_fig;
        
    else %if new figure
        
        h.f = varargin{1};
        
        %image panel
        h.GUI.hImage = uipanel('Parent',h.f,...
            'units','pixels','fontsize',10,...
            'Position',posImg);
        
        
        %data plot panel
        h.GUI.hDataPlot = uipanel('Parent',h.f,'title','Params:',...
            'units','pixels','fontsize',10,...
            'Position',posDataPlot,'Visible','on');
        
        %params panel
        h.GUI.hFilter = uipanel('Parent',h.f,'title','Filters:',...
            'units','pixels','fontsize',10,...
            'Position',posFilters,'Visible','on');
        
        
        
        %input panel
        h.GUI.hInp = uipanel('Parent',h.f,'title','Input Parameters:',...
            'units','pixels','fontsize',10,...
            'Position',posInput);
        
        % voltage panel
        h.GUI.hVax = axes('Parent', h.f, ...
            'Units', 'pixels', 'NextPlot','add',...
            'Position',posVaxes);
        title(h.GUI.hVax,'voltage');
        xlabel(h.GUI.hVax,'t[nsec]');
        ylabel(h.GUI.hVax,'V[mV]');
        
        
        
        
        h.cnames={'color','min(L)','max(L)','std(L)','mean(L)','min(C)','max(C)','std(C)','mean(C)','SNR(C)','S','X'};
        c_width = cell(size(h.cnames));
        c_width(:) = {68};
        c_width(end-1:end) = {20};
        c_format = cell(size(h.cnames));
        c_format(:) = {'numeric'};
        c_format(end-1:end) = {'logical'};
        c_editable = false(size(h.cnames));
        c_editable(end) = true;
        c_editable(end-1) = true;
        h.GUI.hTbl=uitable('parent',h.f,'ColumnName',h.cnames,'data',{},...
            'units','pixels','position',posTable,'ColumnWidth',...
            c_width,'ColumnFormat',c_format,...
            'columneditable',c_editable,'cellSelectionCallback',@tbl_callback);
        
        drawnow;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % image panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        h.GUI.hImg_ax = axes('Parent',h.GUI.hImage, ...
            'Units', 'pixels',...% YDir,'reverse',...
            'Position',pos_Img_ax,'NextPlot','add','ButtonDownFcn', @callback_draw);
        axis(h.GUI.hImg_ax,'image')
        h.GUI.hImg_ax.YDir = 'reverse';
        h.GUI.caxis_low = uicontrol('Parent',h.GUI.hImage,'Style', 'slider',...
            'Min',0,'Max',1,'Value',0,...
            'Position',pos_caxis_low,...
            'Callback', @callback_slider);
        h.GUI.caxis_high = uicontrol('Parent',h.GUI.hImage,'Style', 'slider',...
            'Min',0,'Max',1,'Value',1,...
            'Position', pos_caxis_high,...
            'Callback', @callback_slider);
        %     h.GUI.export_fig = uicontrol('Parent',h.GUI.hImage,'Style', 'pushbutton',...
        %         'Position', pos_export_fig,'String','export image',...
        %         'Callback', @callback_export_image);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % input panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        in_txt_w = 75;
        pw = get(h.GUI.hInp,'pos');pw=pw(3:4);
        uicontrol('Style','text','parent',h.GUI.hInp,'units','pixels',...
            'pos',[1 pw(2)-2*ROW_H in_txt_w ROW_H],'string','Scope_in:',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        h.GUI.input_file = uicontrol('Style','edit','parent',h.GUI.hInp,'units','pixels',...
            'pos',[in_txt_w+1 pw(2)-2*ROW_H pw(1)-ROW_H-in_txt_w-2*MRGN ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string',DEF_FN_IN);
        uicontrol('style','pushbutton','parent',h.GUI.hInp,'units','pixels',...
            'pos',[pw(1)-ROW_H-MRGN*2/3 pw(2)-2*ROW_H ROW_H ROW_H],...
            'callback',{@callback_selectInputFile,h.GUI.input_file },'string','...');
        
        uicontrol('Style','text','parent',h.GUI.hInp,'units','pixels',...
            'pos',[1 pw(2)-3*ROW_H in_txt_w ROW_H],'string','codeLength:',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        h.GUI.code_length = uicontrol('Style','edit','parent',h.GUI.hInp,'units','pixels',...
            'pos',[in_txt_w+1 pw(2)-3*ROW_H pw(1)-9*ROW_H-in_txt_w-2*MRGN ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','26');
        
        h.GUI.load_data = uicontrol('style','pushbutton','parent',h.GUI.hInp,'units','pixels',...
            'pos',[1 pw(2)-4*ROW_H+MRGN pw(1)-MRGN ROW_H-MRGN*2],...
            'callback',@callback_load_from_file_data,'string','LOAD DATA','fontWeight','bold');
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % data plot panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        pw = get(h.GUI.hDataPlot,'pos');pw=pw(3:4);
        
        DEF_MEMSTABLE = {
            '\\invcam322\Ohad\data\lidar\memsTables\2014-12-01\60Hz\memsTable.mat',...
            '\\invcam322\ohad\data\lidar\memsTables\2015-12-22\60Hz\memsTable.mat',...
            '\\invcam322\Ohad\data\lidar\memsTables\2015-01-22\60hz\memsTable.mat'    
            };
        res=arrayfun(@(i) regexp(DEF_MEMSTABLE{i},'(?<Y>\d+)-(?<M>\d+)-(?<D>\d+)','names'),1:3);
        
        tblVals = arrayfun(@(i) [i.Y '-' i.M '-' i.D],res,'uni',false);
        
        h.GUI.hTblXY = uicontrol('Style','popupmenu','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[txtW+1 pw(2)-2*ROW_H pw(1)-txtW-MRGN ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string',tblVals,'userdata',DEF_MEMSTABLE);
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[1 pw(2)-2*ROW_H txtW ROW_H],'string','MEMS_tbl:',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        
        
        xstart=1;
        x = xstart;
        l_num = 3.5;
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','Range(t)',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.time_range = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','2000','callback',@updateGUI);
        x = x+editW+MRGN;
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','Range(s)',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.spatial_radius = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','20','callback',@updateGUI);
        x=xstart;
        
        
        %ADC
        l_num = l_num+1;
        
        
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','vL[mv]',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.vl = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','0','callback',@callabck_adcLH);
        x = x+editW+MRGN;
        
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','vH[mv]',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.vh = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','80','callback',@callabck_adcLH);
        x = x+editW+MRGN;
        
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','nbits',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.nbits = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','0','callback',@callabck_adcLH);
        %wh
        x=xstart;
        l_num = l_num+1;
        
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','width',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.imgW = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','640','callback',@callabck_adcLH);
        x = x+editW+MRGN;
        uicontrol('Style','text','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H txtW ROW_H],'string','height',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        x = x+txtW;
        h.GUI.imgH = uicontrol('Style','edit','parent',h.GUI.hDataPlot,'units','pixels',...
            'pos',[x pw(2)-l_num*ROW_H editW ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string','480','callback',@callabck_adcLH);
        
        %         h.GUI.inputType = uibuttongroup('parent',h.GUI.hDataPlot,'units','pixels',...
        %             'pos',[xstart pw(2)-3*ROW_H-5 (txtW+ROW_H)*2 ROW_H],'SelectionChangedFcn',@updateGUI);
        %         uicontrol('style','radiobutton','parent',h.GUI.inputType,'units','pixels','pos',[1 1 txtW+ROW_H ROW_H]','string','Scope raw')
        %         uicontrol('style','radiobutton','parent',h.GUI.inputType,'units','pixels','pos',[1+txtW+ROW_H  1 txtW+ROW_H ROW_H]','string','SlowSim')
        
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % filters panel
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        pp = h.GUI.hFilter.Position;
        
        
        h.GUI.filGroup = uitabgroup('parent',h.GUI.hFilter);
        
        h.GUI.simFilter.tabH = uitab(h.GUI.filGroup,'Title','Simulator');
        h.GUI.asicFilter.tabH = uitab(h.GUI.filGroup,'Title','ASIC','units','pixels');
        
        
        %=========================
        %===== simulator tab =====
        %=========================
        filters = {'Butterworth' 'Cheby I' 'Cheby II' 'Eliptical'};
        defL = {'250','','','40'};
        defH = {'500','50','50',''};
        defO = {'3','1','3','1'};
        
        for i =1:2
            p = [1  pp(4)-170*i   pp(3)-3 120];
            h.GUI.simFilter.filters_tg(i) = uitabgroup('parent',h.GUI.simFilter.tabH,'units','pixels','position',p);
            tabs = cell(1,length(filters));
            for j=1:length(filters)
                
                tabs{j} = uitab(h.GUI.simFilter.filters_tg(i),'Title',filters{j});
                tab = tabs{j};
                
                %cutoff low
                uicontrol('style','text','string','Cutoff L','parent',tab,'position',[5 p(4)-50 50 20])
                strct.cL=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-50 50 20],'string',defL{j});
                uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-50 30 20])
                
                %cutoff high
                uicontrol('style','text','string','Cutoff H','parent',tab,'position',[5 p(4)-75 50 20])
                strct.cH=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-75 50 20],'string',defH{j});
                uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-75 30 20])
                
                %order
                uicontrol('style','text','string','order   ','parent',tab,'position',[5 p(4)-100 50 20])
                strct.n=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-100 50 20],'string',defO{j});
                
                %ripple pass
                if( strcmp(filters{j},'Cheby I') || strcmp(filters{j},'Eliptical') )
                    uicontrol('style','text','string','Ripple pass','parent',tab,'position',[155 p(4)-50 60 20])
                    strct.rP=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[220 p(4)-50 50 20],'string','3');
                    uicontrol('style','text','string','db ','parent',tab,'position',[270 p(4)-50 30 20])
                end
                
                %ripple stop
                if( strcmp(filters{j},'Cheby II') || strcmp(filters{j},'Eliptical') )
                    line = 0;
                    if(strcmp(filters{j},'Eliptical'))
                        line = 25;
                    end
                    uicontrol('style','text','string','Ripple stop','parent',tab,'position',[155 p(4)-50-line 60 20])
                    strct.rS=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[220 p(4)-50-line 50 20],'string','60');
                    uicontrol('style','text','string','db ','parent',tab,'position',[270 p(4)-50-line 30 20])
                end
                
                is_on = 1;
                strct.vis = uicontrol('style','checkbox','string','Is On?','parent',tab,'position',[p(3)-125 p(4)-100 100 20],'value',is_on);
                
                set(tab,'userdata',strct);
            end
            tabgroup = h.GUI.simFilter.filters_tg(i);
            tabgroup.SelectedTab = tabs{ strcmp('Butterworth',filters) };
            
        end
        
        %abs
        h.GUI.simFilter.abs = uicontrol('style','checkbox','string','apply ABS','parent',h.GUI.simFilter.tabH,...
            'position',[1 200+30 100 20],'value',1);
        
        
        
        
        %=========================
        %         ASIC tab
        %=========================
        
        p = get(h.GUI.asicFilter.tabH,'pos');
        p = p(3:4);
        uicontrol('Style','text','parent',h.GUI.asicFilter.tabH,'units','pixels',...
            'pos',[1 p(2)-3*ROW_H txtW ROW_H],'string','ASIC',...
            'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
        h.GUI.asicFilter.asicParamFile = uicontrol('Style','edit','parent',h.GUI.asicFilter.tabH,'units','pixels',...
            'pos',[txtW+1 p(2)-3*ROW_H p(1)-ROW_H-txtW-2*MRGN ROW_H],'horizontalAlignment','left','fontsize',10,...
            'backgroundcolor','w','string',DEF_ASIC_IN,'Callback',@asicFileChange);
        h.GUI.asicFilter.asicPanel = uipanel('parent',h.GUI.asicFilter.tabH,'units','pixels','position',[1 1 p(1) p(2)-4*ROW_H]);
        
        %
        % h.slowChanSimParams = xml2structWrapper('\\invcam322\ohad\data\lidar\simulatorParams\slowChannel\slowChanSimParams.xml');
        % w_text = 100;
        %
        % pos = pp;
        % pos(1) = 1;
        % pos(3) = w_text;
        % pos(4) = 100;
        %
        %
        % % ABS
        % uicontrol('style','text','string','choose ABS curve:','parent',h.GUI.asicFilter.tabH,...
        %     'position',pos);
        % pos(1) = pos(1)+w_text;
        % w_pop = 80;
        % pos(3) = w_pop;
        %
        % freqs = {'250MHz', '500MHz'};
        % h.GUI.asicFilter.tabH_abs_pop_f = uicontrol('style','popupmenu','parent',h.GUI.asicFilter.tabH,...
        %     'position',pos,'string',freqs);
        %
        % curves = {'00','01', '10', '11'};
        % pos(1) = pos(1)+w_pop+5;
        % h.GUI.asicFilter.tabH_abs_pop_curve = uicontrol('style','popupmenu','parent',h.GUI.asicFilter.tabH,...
        %     'position',pos,'string',curves);
        %
        
        
        
        
        %=========================
        %   run buttons % Fs
        %=========================
        p = h.GUI.hFilter.Position;
        
        %Fs
        uicontrol('style','text','string','sampling freq:','parent',h.GUI.hFilter,...
            'position',[1 40 80 20]);
        h.GUI.Fs = uicontrol('style','edit','string','125','parent',h.GUI.hFilter,...
            'position',[1+80 40 60 20]);
        uicontrol('style','text','string','MHz','parent',h.GUI.hFilter,...
            'position',[1+100+40 40 40 20]);
        
        
        uicontrol('style','pushbutton','parent',h.GUI.hFilter,'units','pixels',...
            'pos',[1   5   (p(3)-MRGN)/3   2*ROW_H-MRGN*2],...
            'callback',{@callback_run,'none'},'string','RUN','fontWeight','bold');
        
        uicontrol('style','pushbutton','parent',h.GUI.hFilter,'units','pixels',...
            'pos',[1+(p(3)-MRGN)/3   5   (p(3)-MRGN)/3   2*ROW_H-MRGN*2],...
            'callback',{@callback_run,'coarse'},'string','<HTML><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;RUN</b><BR><small>(force coarse sync)</small>');
        uicontrol('style','pushbutton','parent',h.GUI.hFilter,'units','pixels',...
            'pos',[1+(p(3)-MRGN)/3*2   5   (p(3)-MRGN)/3   2*ROW_H-MRGN*2],...
            'callback',{@callback_run,'fine'},'string','<HTML><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;RUN</b><BR><small>(force fine sync)</small>');
        
        
        
        
        set(h.f,'SizeChangedFcn',@createGUI);
        guidata(h.f,h);
        asicFileChange(h.f);
    end
    
    
    
    
end


function asicFileChange(varargin)
    h = guidata(varargin{1});
    asicp = xml2structWrapper(h.GUI.asicFilter.asicParamFile.String);
    
    fn = fieldnames(asicp);
    p = get(h.GUI.asicFilter.asicPanel,'pos');
    p = p(3:4);
    h.asicOptions=struct();
    delete(get(h.GUI.asicFilter.asicPanel,'children'));
    for i=1:length(fn)
        curves = fieldnames(asicp.(fn{i}));
        curves= curves(~strcmp(curves,'axis'));
        curves = strcat(curves);
          uicontrol('style','text','string',fn{i},'parent',h.GUI.asicFilter.asicPanel,...
            'position',[1   p(2)-(i+1)*25 100 25]);
     
        h.asicOptions.(fn{i}) = uicontrol('style','popupmenu','parent',h.GUI.asicFilter.asicPanel,...
            'position',[100 p(2)-(i+1)*25 p(1)-110 25],'string',curves);
        %
        
        
    end
    guidata(h.f,h);
end

function s=comboString(h)
    s=get(h,'string');
    v = get(h,'Value');
    s = s{v};
end
% function callback_export_image(varargin)
% h= guidata(varargin{1});
%   F=getimage(h.GUI.hImg_ax); %select axes in GUI
%    c = caxis(h.GUI.hImg_ax);
%     figure(); %new figure
%     imagesc(F); %show selected axes in new figure
%     colormap gray
%     caxis(c)
% %     [FileName,PathName] = uiputfile();
% %      print(fig,[PathName '\' FileName] ,'-dpng') %save figure
% %    close(fig); %and close it
% end

function callback_slider(varargin)
    h= guidata(varargin{1});
    h.GUI.vl.String = h.GUI.caxis_low.Value;
    h.GUI.vh.String = h.GUI.caxis_high.Value;
    imagescWithADC(h);
    
end
function callabck_adcLH(varargin)
    h= guidata(varargin{1});
    vL = str2double(h.GUI.vl.String);
    vH = str2double(h.GUI.vh.String);
    if(vL>vH)
        return;
    end
    
    h.GUI.caxis_low.Value = vL;
    h.GUI.caxis_high.Value = vH;
    
    h.GUI.caxis_low.Min = vL;
    h.GUI.caxis_low.Max = vH;
    
    h.GUI.caxis_high.Min = vL;
    h.GUI.caxis_high.Max = vH;
    if(isfield(h,'DATA') && isfield(h.DATA,'vg'))
        imagescWithADC(h);
        updateGUI(h.f);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
% filtes func
%%%%%%%%%%%%%%%%%%%%%%%%
function [bp,ap]=abFromTab(tab,Tc)
    t = tab.Title;
    b = tab.UserData;
    if( b.vis.Value == 0)
        bp = nan;
        ap = nan;
    else
        switch(t)
            case 'Butterworth'
                [bp,ap]=abFromB_butter(b,Tc);
            case 'Eliptical'
                [bp,ap]=abFromB_ellip(b,Tc);
            case 'Cheby I'
                [bp,ap]=abFromB_cheby1(b,Tc);
            case 'Cheby II'
                [bp,ap]=abFromB_cheby2(b,Tc);
        end
    end
end

function [bp,ap]=abFromB_cheby2(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'));
    fH = str2double(get(b.cH,'string'));
    wL = fL*1e-3*Tc*2;
    wH = fH*1e-3*Tc*2;
    rS = str2double(get(b.rS,'string'));
    if(isnan(wL) && isnan(wH))
        return;
    elseif(~isnan(wL) && isnan(wH))
        [bp,ap]=cheby2(N,rS,wL,'high');
    elseif(isnan(wL) && ~isnan(wH))
        [bp,ap]=cheby2(N,rS,wH,'low');
    else
        if(wL>=wH)
            return;
        else
            [bp,ap]=cheby2(N,rS,[wL wH]);
        end
    end
    
end

function [bp,ap]=abFromB_cheby1(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    rP = str2double(get(b.rP,'string'));
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=cheby1(N,rP,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=cheby1(N,rP,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=cheby1(N,rP,[fL fH]);
        end
    end
end

function [bp,ap]=abFromB_ellip(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    rP = str2double(get(b.rP,'string'));
    rS = str2double(get(b.rS,'string'));
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=ellip(N,rP,rS,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=ellip(N,rP,rS,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=ellip(N,rP,rS,[fL fH]);
        end
    end
end

function [bp,ap]=abFromB_butter(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'));
    fH = str2double(get(b.cH,'string'));
    wL = fL*1e-3*Tc*2;
    wH = fH*1e-3*Tc*2;
    if(isnan(wL) && isnan(wH))
        return;
    elseif(~isnan(wL) && isnan(wH))
        [bp,ap]=butter(N,wL,'high');
    elseif(isnan(wL) && ~isnan(wH))
        [bp,ap]=butter(N,wH,'low');
    else
        if(wL>=wH)
            return;
        else
            [bp,ap]=butter(N,[wL wH]);
        end
    end
end










% function snrUpdate(varargin)
% h= guidata(varargin{1});
% delete(h.snrTextH);
% if(~isempty(h.GUI.hTbl.Data))
% sigIndx = cell2mat(h.GUI.hTbl.Data(:,end-1));
% muS = mean(cell2mat(h.GUI.hTbl.Data(sigIndx,5)));
% muN = mean(cell2mat(h.GUI.hTbl.Data(~sigIndx,5)));
% stdN = sqrt(mean(cell2mat(h.GUI.hTbl.Data(~sigIndx,4)).^2));
% h.snrTextH = text(h.GUI.hVax.XLim(1),h.GUI.hVax.YLim(2),sprintf('\nSNR: %f',(muS-muN)/stdN),'parent',h.GUI.hVax,'fontsize',15);
% guidata(h.f,h);
% end
% end

function tbl_callback(varargin)
    h= guidata(varargin{1});
    if(isempty(varargin{2}.Indices))
        return;
    end
    
    rowIndx  = varargin{2}.Indices(1);
    if(varargin{2}.Indices(2)==size(h.GUI.hTbl.Data,2))
        %delete row
        delete(h.plotHandles(rowIndx,ishandle(h.plotHandles(rowIndx,:))));
        h.plotHandles(rowIndx,:)=[];
        h.GUI.hTbl.Data(rowIndx,:)=[];
        %     h.t_acc(rowIndx)=[];
        h.xy(rowIndx,:)=[];%%%%%%%%%
    end
    guidata(h.f,h);
end


function imagescWithADC(h)
    hh = findobj(h.GUI.hImg_ax,'type','image');
    if(~isempty(hh))
        delete(hh);
    end
    vL = str2double(h.GUI.vl.String)/1000;
    vH = str2double(h.GUI.vh.String)/1000;
    if (vL>vH)
        return;
    end
    n = str2double(h.GUI.nbits.String);
    if(n>0)
        vgADC = round((min(vH,max(vL,h.DATA.vg))-vL)/(vH-vL)*(2^n-1));
        
    else
        vgADC  = h.DATA.vg;
        clmis = prctile(vgADC(~isnan(vgADC(:))),[1 99])+[0 1e-3];
        caxis(h.GUI.hImg_ax,clmis);
    end
    % vgADC = medfilt2(vgADC,[5 3]);
    if(0)
        vgADC = medfilt2(double(vgADC),[3 3]);
        p=log(255)/log(max(vgADC(:)));
        vgADC= (double(vgADC).^p)*(2^(n-8)-1);
        
    end
    imagesc(vgADC,'parent',h.GUI.hImg_ax,'hittest','off');
    caxis(h.GUI.hImg_ax,[0 (2^n-1)]);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function imageDisplay(h)
    imagescWithADC(h);
    
    colorbar(h.GUI.hImg_ax,'Location','southoutside');
    colormap(h.GUI.hImg_ax,gray(256));
    
    h.GUI.hImg_ax.Visible='on';
    h.GUI.hFilter.Visible='on';
end


function callback_load_from_file_data(varargin)
    h = guidata(varargin{1});
    
    setWatches(h,false);
    
    delete(h.plotHandles(ishandle(h.plotHandles(:))))
    h.xy = [];
    h.plotHandles=[];
    h.GUI.hTbl.Data={};
    
    h.loaded_tblXY = h.GUI.hTblXY.UserData{h.GUI.hTblXY.Value};
    h.loaded_input = h.GUI.input_file.String;
    
    if(isdir(h.loaded_input))
        callback_runbatch(varargin);
    else
        
        
        [h.DATA.vscope,h.DATA.vscopeFs, h.DATA.mirTicks] = slowChanEvalRawData('fn_in',h.loaded_input);
        
        h.GUI.load_data.BackgroundColor = 'g';
    end
    
    setWatches(h,true);
    
    guidata(h.f,h);
end



function setWatches(h,mode)
    
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

function callback_run(varargin)
    h = guidata(varargin{1});
    if (isdir(h.GUI.input_file.String))
        callback_runBatch(varargin{:});
    else
        try
            callback_runWrapper(varargin{:})
        catch e,
            errordlg(e.message);
            disp(cell2str(arrayfun(@(x) [x.file 9 '->' 9 x.name '@' num2str(x.line)],e.stack,'uni',false),13));
            h = guidata(varargin{1});
            setWatches(h,true);
        end
    end
end





function callback_runBatch(varargin)
    % h = guidata(varargin{1});
    % setWatches(h,false);
    %
    % h.loaded_tblXY = h.GUI.hTblXY.UserData{h.GUI.hTblXY.Value};
    % h.loaded_input = h.GUI.input_file.String;
    %
    % baseDir = h.loaded_input;
    % tblXYfn = h.loaded_tblXY;
    %
    % vslowFs = str2double(h.GUI.Fs.String);
    %
    % rawfns = [dirFiles(baseDir,'*.bin');dirFiles(baseDir,'*.h5')];
    % for i=1:length(rawfns)
    %     fn_in = rawfns{i};
    %     [pathstr,name,~] = fileparts(fn_in);
    %     %     if( exist([pathstr,'\',name,'.png'],'file'))
    %     %         continue;
    %     %     end
    %
    %
    %
    %     try
    %
    %         h.GUI.input_file.String = fn_in;
    %         guidata(h.f,h);
    %         callback_load_from_file_data(varargin{:});
    %         h= guidata(h.f);
    %         setWatches(h,false);
    %
    %         raw_data.vscope = h.DATA.vscope;
    %         raw_data.vscopeFs = h.DATA.vscopeFs;
    %         raw_data.t = h.DATA.t;
    %         raw_data.mirTicks = h.DATA.mirTicks;
    %
    %
    %         [bpBeforeAbs,apBeforeAbs]=abFromTab(h.GUI.simFilter.filters_tg(1).SelectedTab,1/h.DATA.vscopeFs);
    %         is_abs = h.GUI.simFilter.abs.Value;
    %         [bpAfterAbs,apAfterAbs]=abFromTab(h.GUI.simFilter.filters_tg(2).SelectedTab,1/h.DATA.vscopeFs);
    %         width=str2double(h.GUI.imgW.String);
    %         height=str2double(h.GUI.imgH.String);
    %
    %
    %
    %
    %
    %         [h.DATA.vg,h.DATA.vslow,h.DATA.vslowFs,h.DATA.funcData] = ...
    %             slowChanEval('tblXYfn',tblXYfn,'fn_in',fn_in,'raw_data',raw_data,'abs',is_abs,'vslowFs',vslowFs,...
    %             'filter_before',[bpBeforeAbs;apBeforeAbs],'filter_after',[bpAfterAbs;apAfterAbs],'verbose',false,'w',width,'h',height);
    %
    %         imageDisplay(h);
    %         callback_print(varargin{:});
    %         drawnow;
    %
    %         h.GUI.hImg_ax.Visible='on';
    %         h.GUI.hFilter.Visible='on';
    %
    %
    %         guidata(h.f,h);
    %         updateGUI(h.f);
    %
    %
    %
    %
    %
    %     catch ex
    %         display(['ERROR in ' name ':' ex.message])
    %         continue;
    %     end
    % end
    %
    % h.GUI.input_file.String = baseDir;
    % h.loaded_input = baseDir;
    %
    % setWatches(h,true);
    % guidata(h.f,h);
    
end


function callback_runWrapper(varargin)
    
    h = guidata(varargin{1});
    syncEnforce = varargin{3};
    setWatches(h,false);
    
    %the data wasn't loaded OR the data was changed
    if( ~isfield(h,'DATA') || ...
            ~strcmp(h.loaded_tblXY, h.GUI.hTblXY.UserData{h.GUI.hTblXY.Value}) || ...
            ~strcmp(h.loaded_input , h.GUI.input_file.String)   )

        callback_load_from_file_data(varargin{1});
        setWatches(h,false);
        h= guidata(h.f);
    end
    
    %build raw data struct
    raw_data.vscope = h.DATA.vscope;
    raw_data.vscopeFs = h.DATA.vscopeFs;
    
    raw_data.mirTicks = h.DATA.mirTicks;
    
    
    if(strcmp(h.GUI.filGroup.SelectedTab.Title,'Simulator'))
        %build filters
        [BeforeAbs,absv,AfterAbs] = buildSimFilters(h);
        filterFunction =@(x,fs) applySimFilter(x,fs,BeforeAbs,absv,AfterAbs);
    else
        optVect = structfun(@(x) comboString(x),h.asicOptions,'uni',false);
        fn = h.GUI.asicFilter.asicParamFile.String;
        filterFunction =@(x,fs) applyAsicFilter(x,fs,fn,optVect);

    end
    
    
    Fs = str2double(h.GUI.Fs.String);
    width=str2double(h.GUI.imgW.String);
    height=str2double(h.GUI.imgH.String);
    
    %run with filters
    [h.DATA.vg,h.DATA.vslow,h.DATA.vslowFs,h.DATA.funcData] = ...
        slowChanEval('tblXYfn',h.GUI.hTblXY.UserData{h.GUI.hTblXY.Value},'code_length',str2double(h.GUI.code_length.String),...
        'fn_in',h.GUI.input_file.String,'verbose',false,'raw_data',raw_data,'filterFunction',filterFunction,'vslowFs',Fs,'syncenforce',syncEnforce,'w',width,'h',height);
    
    
    imageDisplay(h);
    
    h.GUI.hImg_ax.Visible='on';
    h.GUI.hFilter.Visible='on';
    setWatches(h,true);
    
    guidata(h.f,h);
    updateGUI(h.f);
end





function [BeforeAbs,abs,AfterAbs] = buildSimFilters(h)
    
    [BeforeAbs.bp,BeforeAbs.ap]=abFromTab(h.GUI.simFilter.filters_tg(1).SelectedTab,1/h.DATA.vscopeFs);
    abs = h.GUI.simFilter.abs.Value;
    [AfterAbs.bp,AfterAbs.ap]=abFromTab(h.GUI.simFilter.filters_tg(2).SelectedTab,1/h.DATA.vscopeFs);
end







function callback_selectInputFile(varargin)
    
    hEdit = varargin{3};
    [path, ~] = fileparts(hEdit.String);
    [f,d]=uigetfile('*.*','Select file', [path, '\']);
    hEdit.String = [d,f];
    
end



function callback_draw(varargin)
    
    h = guidata(varargin{1});
    
    h.v_p.Visible = 'on';
    
    x0=h.GUI.hImg_ax.CurrentPoint(1);
    y0=h.GUI.hImg_ax.CurrentPoint(3);
    h.xy(end+1,:)=[x0 y0];
    guidata(h.f,h);
    updateGUI(h.f);
    
    
    
    
    
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main calc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateGUI(varargin)
    h=guidata(varargin{1});
    f = h.f;
    
    h=plot_on_image(h);
    
    guidata(f,h);
    % snrUpdate(f);
end


function h=plot_on_image(h)
    vdataFs = h.DATA.vslowFs;
    time_range = str2double(h.GUI.time_range.String);
    ta = ( -time_range/2:1/vdataFs:time_range/2); %nsec
    r = str2double(h.GUI.spatial_radius.String); %[pixels]
    
    [vgY,vgX]=ndgrid(1:size(h.DATA.vg,1),1:size(h.DATA.vg,2));
    
    circPts  = r*exp(1j*linspace(0,2*pi,100));
    
    c = lines(size(h.xy,1));
    delete(h.plotHandles(ishandle(h.plotHandles(:))))
    
    h.plotHandles = nan(size(h.xy,1),3);
    
    imgData =h.GUI.hImg_ax.Children(1).CData;
    
    for i=1:size(h.xy,1)
        xy = h.xy(i,:);
        t = t4xy(xy,h.DATA.funcData) + ta;
    
        xy_line = xy4t(t,h.DATA.funcData);
        dataLine=h.DATA.vslow(round(t*vdataFs+1));
        if(xy_line(end,1)<xy_line(1,1))
            dataLine = fliplr(dataLine);
        end
        
        dataCirc = imgData(sum((bsxfun(@minus,[vgX(:) vgY(:)],xy)).^2,2)<r^2);
        add_stats(h,i,dataLine,dataCirc,c(i,:));
        
        xy0 = xy;
        h.plotHandles(i,1)=plot(h.GUI.hImg_ax, xy_line(:,1),xy_line(:,2),'color',c(i,:),'HitTest','off','linewidth',2);
        h.plotHandles(i,2)=plot(h.GUI.hImg_ax, xy0(1)+real(circPts),xy0(2)+imag(circPts),'color',c(i,:),'HitTest','off','linewidth',2);
        
        
        if(mod(dataLine,2)~=0)
            dataLine = dataLine(1:end-1);
        end

%         h.plotHandles(i,3)= fftplot(dataLine,vdataFs*1e9,1,h.GUI.hVax,c(i,:));
%         set(h.GUI.hVax,'YScale','log');
         h.plotHandles(i,3)=plot(h.GUI.hVax,(0:length(dataLine)-1)/vdataFs, dataLine,'color',c(i,:),'HitTest','off');
        
    end
    
end



function h = add_stats(h,indx,dataLine,dataCirc,col)
    if(indx>size(h.GUI.hTbl.Data,1))
        h.GUI.hTbl.Data =[h.GUI.hTbl.Data; [cell(indx-size(h.GUI.hTbl.Data,1),10) {true} {true}]];
    end
    calcFun = @(x) [min(x) max(x) std(x) mean(x)];
    rowdata = [calcFun(dataLine)*1e3 calcFun(dataCirc)  mean(dataCirc)/std(dataCirc)];
    
    %hex color stat
    hex_color(:,2:7) = reshape(sprintf('%02X',round(col*255).'),6,[]).';
    hex_color(:,1) = '#';
    hex_color = char(hex_color);
    
    colergen = @(color,text) ['<html><table border=0 width=400 bgcolor=',color,'><TR><TD>',text,'</TD></TR> </table></html>'];
    h.GUI.hTbl.Data{indx,1} = colergen(hex_color,'');
    h.GUI.hTbl.Data(indx,2:end-2)=num2cell(rowdata);
    h.GUI.hTbl.Data{indx,end} = false;
    
end




function [a,vOut] = fftplot(v,fSample,verbose,parent,color)
if ~exist('verbose','var');
    verbose = 1;
end
if(any(size(v)==1))
    v=v(:);
end
if(mod(size(v,1),2)~=0)
    error('input length should be even');
end
n = size(v,1);
if(~exist('fSample','var'))
    fSample = 1;
    xlbl = '$\frac{1}{pixel}$';
else
    xlbl = 'Frequency';
end
fx = linspace(0,fSample/2,n/2);
V = abs(fft(v));
vOut(:,1) = fx;
vOut(:,2) = V(1:n/2,:);

if verbose
    a=semilogy(parent,fx,V(1:n/2,:),'Color',color,'HitTest','off');
    grid(parent,'on');
    xlabel(parent,xlbl,'interpreter','latex');
    ylabel(parent,'Power');
    set(parent,'YScale','log');
else
    a=[];
end
end

