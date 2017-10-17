function AccuracyTableGenerator()
%  mcc -m AccuracyTableGenerator.m -d \\ger\ec\proj\ha\perc\SA_3DCam\ohad\share\AccuracyTableGenerator\
% Utils.correlator(1,1)
INDOOR_AMBIENT = 0.76;
OUTDOOR_AMBIENT = 4.5;
TRGT_ACC = 10;
DEF_RANGE = 1000;

N_CONFIG = 8;


txCodes = { 'BK13MC','prop32.1', 'prop64.1','prop128.1'};
txFreq = {'1', '0.5', '0.25'};
rxFreq = {'16','8','4'};


if(~exist('AccuracyTableGeneratorDefaults.xml','file'))
    defSimParams = defSimParams_gen(txCodes,txFreq,rxFreq,N_CONFIG);
else
    defSimParams = xml2structWrapper('AccuracyTableGeneratorDefaults.xml');
    names = fieldnames(defSimParams);
    names(cellfun(@isempty,strfind(fieldnames(defSimParams),'simConfig'))) = [];
    for i=1:length(names)
        defSimParams.(names{i}).tx_f = num2str(defSimParams.(names{i}).tx_f);
        defSimParams.(names{i}).rx_f = num2str(defSimParams.(names{i}).rx_f);
    end
    if( length(names) ~= N_CONFIG) %someone had changed the N_CONFIG...
        defSimParams = defSimParams_gen(txCodes,txFreq,rxFreq,N_CONFIG);
    end
end

rH = 20;
winH = 290+(-0.5+N_CONFIG*1.5)*rH;
winW = 490;

txtW = 150;

numW = 50;
h.f = figure('units','pixels','position',[0 0 winW winH],'menubar','none','toolbar','none','numberTitle','off','name','LIDAR simulator runner','resize','off','userdata','structGUI');
centerfig(h.f);

% %%%%%%%%%%%%%%%%%%%%%
% input params
% %%%%%%%%%%%%%%%%%%%%%

h.input_params_panel = uipanel('Parent',h.f,'title','Input Parameters:',...
    'units','pixels','fontsize',10,...
    'Position',[ 5 winH-3*rH-5 winW-10 3*rH]);

i=1.5;

i=i-1;
uicontrol('Style','text','parent',h.input_params_panel,'units','pixels'                           ,'pos',[5         rH*i txtW rH],'string','Simulator parameters file name','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.simulatorParamsFile=uicontrol('Style','edit','parent',h.input_params_panel,'units','pixels'     ,'pos',[txtW+5    rH*i winW-(txtW+5)-rH-30 rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',defSimParams.simulatorParamsFile);
uicontrol('style','pushbutton','parent',h.input_params_panel,'units','pixels'                     ,'pos',[5+txtW+winW-(txtW+5)-rH-30 rH*i rH rH],'callback',{@callback_selectInputFile,h.simulatorParamsFile,'xml'},'string','...');

% %%%%%%%%%%%%%%%%%%%%%
% override params
% %%%%%%%%%%%%%%%%%%%%%
p = h.input_params_panel.Position;
h.override_params_panel = uipanel('Parent',h.f,'title','Override Parameters:',...
    'units','pixels','fontsize',10,...
    'Position',[ 5 p(2)-4.5*rH winW-10 4.5*rH]);

i=3.3;
% h.t_button_table = uicontrol('Style','togglebutton','parent',h.override_params_panel,'units','pixels'  ,'pos',[37            rH*i+5 txtW rH*1.5],'string','Table','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'callback', @t_button_callback,'Value',1);
% h.t_button_single = uicontrol('Style','togglebutton','parent',h.override_params_panel,'units','pixels' ,'pos',[37+txtW+20    rH*i+5 txtW rH*1.5],'string','Single','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'callback', @t_button_callback,'Value',0);



i=i-1;
h.overideParams.ambientIndoor_text=uicontrol('Style','text','parent',h.override_params_panel,'units','pixels'                                   ,'pos',[5         rH*i txtW rH],'string','Ambient indoor[nw]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.overideParams.ambientIndoor     =uicontrol('Style','edit','parent',h.override_params_panel,'units','pixels'     ,'pos',[txtW+5    rH*i numW rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',num2str(INDOOR_AMBIENT));
%if single:
h.overideParams.range_text=uicontrol('Style','text','parent',h.override_params_panel,'units','pixels'                                   ,'pos',[5         rH*i txtW rH],'string','Range [mm]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'),'visible','off');
h.overideParams.range     =uicontrol('Style','edit','parent',h.override_params_panel,'units','pixels'     ,'pos',[txtW+5    rH*i numW rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',num2str(DEF_RANGE),'visible','off');

i=i-1;
h.overideParams.ambientOutdoor_text=uicontrol('Style','text','parent',h.override_params_panel,'units','pixels'                                   ,'pos',[5          rH*i txtW rH],'string','Ambient outdoor[nw]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.overideParams.ambientOutdoor     =uicontrol('Style','edit','parent',h.override_params_panel,'units','pixels'     ,'pos',[txtW+5    rH*i numW rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',num2str(OUTDOOR_AMBIENT));
i=i-1;
h.trgtAcc_text=uicontrol('Style','text','parent',h.override_params_panel,'units','pixels'                                   ,'pos',[5         rH*i txtW rH],'string','Target accuracy[%]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.trgtAcc     =uicontrol('Style','edit','parent',h.override_params_panel,'units','pixels'     ,'pos',[5+txtW rH*i numW rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',num2str(TRGT_ACC));


% %%%%%%%%%%%%%%%%%%%%%
% config params
% %%%%%%%%%%%%%%%%%%%%%
p = h.override_params_panel.Position;
h.config_params_panel = uipanel('Parent',h.f,'title','Configuration:',...
    'units','pixels','fontsize',10,...
    'Position',[ 5 p(2)-(1.45*(N_CONFIG+1)*rH+30) winW-10 1.45*(N_CONFIG+1)*rH+30]);

p = h.config_params_panel.Position;
%title
uicontrol('Style','text','parent',h.config_params_panel,'units','pixels' ,'pos',[5 p(4)-2*rH winW-20 rH],...
    'string','               Name                           Code          Avraging    Tx freq   sample freq','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
uicontrol('Style','text','parent',h.config_params_panel,'units','pixels' ,'pos',[5 p(4)-3*rH winW-20 rH],...
    'string','                                                                                     [GHz]       [GHz]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));

% panels
nameW = 150;
popupW = 100;
edit_numW = 50;
for i=1:N_CONFIG
    
    
    
    h.config(i).panel = uipanel('Parent',h.config_params_panel,'borderType','none',...
        'units','pixels','fontsize',10,...
        'Position',[ 0 1.3*rH*(N_CONFIG-i)+20 winW-10 1.5*rH]);
    
    h.config(i).checkbox = uicontrol('style','checkbox','units','pixels','Parent',h.config(i).panel,...
        'horizontalAlignment','left','fontsize',10,...
        'position',[5,5,rH,rH],'callback', {@checkbox_callback, i},'value',defSimParams.(['simConfig' num2str(i)]).active);
    
    h.config(i).name_edit = uicontrol('Style','edit','parent',h.config(i).panel,'units','pixels',...
        'pos',[22,5,nameW,rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w',...
        'string',defSimParams.(['simConfig' num2str(i)]).name);
    
    
    % find matching code from defSimParams
    val = find(strcmp(  defSimParams.(['simConfig' num2str(i)]).txCode,txCodes   ));
    
    h.config(i).code_popup = uicontrol('Style', 'popup','parent',h.config(i).panel,...
        'String', txCodes,'Value',val,...
        'Position', [22+nameW+5,5,popupW,rH+2] ,'background','white');
    
    
    % nav
    h.config(i).nav_edit = uicontrol('Style', 'edit','parent',h.config(i).panel,...
        'String', num2str(defSimParams.(['simConfig' num2str(i)]).nav),...
        'Position', [22+nameW+popupW+10,5,edit_numW,rH+2] ,'background','white');
    
    % tx freq
    val = find(strcmp(  defSimParams.(['simConfig' num2str(i)]).tx_f,txFreq   ));
    
    h.config(i).tx_f_popup = uicontrol('Style', 'popup','parent',h.config(i).panel,...
        'String', txFreq,'Value',val,...
        'Position', [22+nameW+popupW+20+edit_numW,5,edit_numW,rH+2] ,'background','white');
    
    
    % sample freq
    val = find(strcmp(  defSimParams.(['simConfig' num2str(i)]).rx_f,rxFreq   ));
    h.config(i).rx_f_popup = uicontrol('Style', 'popup','parent',h.config(i).panel,...
        'String', rxFreq,'Value',val,...
        'Position', [22+nameW+popupW+30+edit_numW+edit_numW,5,edit_numW,rH+2] ,'background','white');
    
    
    
end


%%%%%%%%%%%%%%%
% run button
%%%%%%%%%%%%%%%
uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[winW/2-70 rH/2 140 rH*2],'fontsize',10,'FontWeight','bold','string','run','callback',@callback_run_max_range);


guidata(h.f,h);
for i=1:N_CONFIG
    checkbox_callback(h.config(i).checkbox,[],i);
end
end



%%%%%%%%%%%%%%%%%%%%%%
% some callback funcs
%%%%%%%%%%%%%%%%%%%%%%%

function checkbox_callback(varargin)
h = guidata(varargin{1});
i = varargin{3};

if(h.config(i).checkbox.Value == 1)
    h.config(i).name_edit.Enable = 'on';
    h.config(i).code_popup.Enable = 'on';
    h.config(i).nav_edit.Enable = 'on';
    h.config(i).tx_f_popup.Enable = 'on';
    h.config(i).rx_f_popup.Enable = 'on';
else
    h.config(i).name_edit.Enable = 'off';
    h.config(i).code_popup.Enable = 'off';
    h.config(i).nav_edit.Enable = 'off';
    h.config(i).tx_f_popup.Enable = 'off';
    h.config(i).rx_f_popup.Enable = 'off';
end

end

function callback_selectInputFile(varargin)
htxt = varargin{3};
t= ['*.' varargin{4}];


[path, ~] = fileparts(htxt.String);
[f,d]=uigetfile(t,'Select File', [path, '\']);

if(d~=0)
    htxt.String = [d f];
end

end





function callback_run_max_range(varargin)

h = guidata(varargin{1});
%%%%%%%%%%%
%checks:
%%%%%%%%%%%

%check for valid sim params file
simParamsFile=h.simulatorParamsFile.String;
if(~exist(simParamsFile','file'))
    w = errordlg('sim param file not found', 'AccuracyTableGenerator', 'modal');
    set_watches_wrapper(h,false);
    drawnow;
    waitfor(w);
    set_watches_wrapper(h,true);
    return
end





%wait for the end of the calc
set_watches_wrapper(h,false);

table_range_run(h);



%end of the calc
set_watches_wrapper(h,true);




end



%%%%%%%%%%%%%%%%%%%%%%
%calc menegmant functions
%%%%%%%%%%%%%%%%%%%%%%

% do the end run for table
function table_range_run(h)

%save xls file
[path, ~] = fileparts(h.simulatorParamsFile.String);
[filename, pathname] = uiputfile( '*.xls', 'save *.xls file in...',[path, '\output' datestr(datetime('now'),'yyyymmdd') '.xls']);
if(isempty(filename))
    return;
end
save_file = [pathname,filename];

max_distance = 100000;

dists = [50 250 500 800 1000 1200 1500:250:max_distance];

trgtAcc = str2double(h.trgtAcc.String);

%  get newest override parameters and saves them.
pc = getSimParams(h);
save_params(h);

fw = Firmware();

%start calculations on the table
accTable = nan(length(dists),length(pc));
t=tic;
fprintf('Starting...\n');
fprintf('  %-2s %-20s %-5s %-s\n','##','name','dist','accuracy');
parfor i=1:length(pc)
    accCol = nan(length(dists),1);
    avraging = pc(i).nav;
    
    for j=1:length(dists)
%         fprintf('.');
           fprintf('%-2d %-20s %-5d\n',i,pc(i).name,dists(j)); 

        res = runSingle(pc(i),dists(j),fw,avraging);
        
        
        accThr = (trgtAcc/100)*dists(j);
        if(j>10 && (res.acc>accThr || isnan(res.acc)))
            break;
        end
        if(res.acc<accThr)
            accCol(j)=res.acc;
        end
        fprintf('%-2d %-20s %-5d %-f : END\n',i,pc(i).name,dists(j),accCol(j));
    end
    accTable(:,i)=accCol;
    
end
fprintf('Done(%d minutes).\n',round(toc(t)/60));



[datac,rnames,cnames] = draw_ui_table(accTable, dists,pc);

xls_and_plot(pc, rnames,cnames,datac,dists,accTable,save_file);



end


%actual calc of one range & one param set - the heart of calculations
function res = runSingle(simParams,distance,fw,avraging)

thisfw = copy(fw);
% fw.disp
t=tic;
nMes = 35;
outliersP = 0.25;


simParams.runTime= (length(simParams.laser.txSequence)/simParams.laser.frequency)*(1+nMes*avraging);
simParams.verbose = false;
model =struct('t',[0 simParams.runTime],'r',[ distance  distance],'a',[ 1 1]);


s = RandStream('twister'); % Default seed 0.
RandStream.setGlobalStream(s);


[chA,~,~,res] = Simulator.runSim(model,simParams);
firstTx = (length(simParams.laser.txSequence)/simParams.laser.frequency)*simParams.Comparator.frequency;

chA(1:firstTx)=[];

newregs.GNRL.txCode = simParams.laser.txSequence';
newregs.GNRL.codeLength = length(simParams.laser.txSequence);
newregs.GNRL.tx = 1/simParams.laser.frequency;
newregs.GNRL.sampleRate = simParams.Comparator.frequency/simParams.laser.frequency;
newregs.FRMW.xfov=0;
newregs.FRMW.yfov=0;
thisfw.setRegs(newregs,'struct');


% thisfw.diff(fw);

stats = Utils.sequenceDetector(chA,thisfw,avraging,false,outliersP);





res.acc = stats.std;
res.dprec = stats.mean-distance;
res.range = round(stats.mean);
res.runTime = toc(t);
res.gtRange=distance;
end






%%%%%%%%%%%%%%%%%%%%%%
%help functions
%%%%%%%%%%%%%%%%%%%%%%

%initialize the wanted struct with new patameters
function pc = getSimParams(h)
% colorCell = @(c,v) ['<html><table border=0 width=50 bgcolor=#',reshape(dec2hex(floor(c*255),2)',[],6),'><TR><TD  align="right">',num2str(v),'</TD></TR> </table></html>'];

prms = xml2structWrapper(h.simulatorParamsFile.String);

ambientIndoor = str2double(h.overideParams.ambientIndoor.String);
ambientOtdoor = str2double(h.overideParams.ambientOutdoor.String);

n = length(h.config);

pc(1:2*n)=prms;

for i=1:n
    
    indIndoor = i*2-1;
    indOtdoor = i*2-0;
    
    code_popup_val = h.config(i).code_popup.Value;
    code_name = h.config(i).code_popup.String{code_popup_val};
    if(strfind(code_name,'prop')==1)
        res = regexp(code_name,'(?<cl>[\d]+)\.(?<cn>[\d]+)','names');
        pc(indIndoor).laser.txSequence= Codes.propCode(str2double(res.cl),str2double(res.cn));
    elseif(isequal(code_name,'BK13MC'))
        pc(indIndoor).laser.txSequence = Codes.barker13();
    elseif(isequal(code_name,'golay26MC'))
        pc(indIndoor).laser.txSequence = Codes.golay26();
    else
        h.config(i).checkbox.Value=false;
    end
    pc(indOtdoor).laser.txSequence= pc(indIndoor).laser.txSequence;
       
       
    pc(indIndoor).laser.frequency =      str2double(h.config(i).tx_f_popup.String{h.config(i).tx_f_popup.Value});
    pc(indOtdoor).laser.frequency =      str2double(h.config(i).tx_f_popup.String{h.config(i).tx_f_popup.Value});
    pc(indIndoor).Comparator.frequency = str2double(h.config(i).rx_f_popup.String{h.config(i).rx_f_popup.Value});
    pc(indOtdoor).Comparator.frequency = str2double(h.config(i).rx_f_popup.String{h.config(i).rx_f_popup.Value});
    
        
    pc(indIndoor).environment.ambientNoiseFactor = ambientIndoor;
    pc(indOtdoor).environment.ambientNoiseFactor = ambientOtdoor;
    
    pc(indIndoor).name = [h.config(i).name_edit.String ' - INDOOR'];
    pc(indOtdoor).name = [h.config(i).name_edit.String ' - OUTDOOR'];
    
    pc(indIndoor).nav = str2double(h.config(i).nav_edit.String);
    pc(indOtdoor).nav = pc(indIndoor).nav;
    pc(indIndoor).ok = h.config(i).checkbox.Value;
    pc(indOtdoor).ok = pc(indIndoor).ok;

end

pc = pc(find([pc.ok]));%#ok
end



%builds default simualtion params if the def .xml doesn't exist
function defSimParams = defSimParams_gen(txCodes, txFreq,rxFreq, N_CONFIG)

defSimParams.simulatorParamsFile =  '\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml';

%sim configuration initialization

config_active = {true,     true,   true,  true,   false,false,false,false};
config_name =   {'HD30', 'VGA60', 'QVGA120','QVGA5',' ',' ',' ',' '};
config_txCode = [  2        3         4        4     1   1   1   1];
config_nav  =   [  1        1         1       24     1   1   1   1];
config_tx_f=    [  1        1         1        1     1   1   1   1];
config_rx_f=    [  1        1         1        3     1   1   1   1];
for j=1:N_CONFIG
    i=j;
    if(j>8)
        i=8;
    end
    
    defSimParams.(['simConfig' num2str(j)]).active = config_active{i};
    defSimParams.(['simConfig' num2str(j)]).name = config_name{i};
    defSimParams.(['simConfig' num2str(j)]).txCode = txCodes{  config_txCode(i)  };
    defSimParams.(['simConfig' num2str(j)]).nav = config_nav(i);
    defSimParams.(['simConfig' num2str(j)]).tx_f = txFreq{config_tx_f(i)};
    defSimParams.(['simConfig' num2str(j)]).rx_f = rxFreq{config_rx_f(i)};
    
end

end



%saves new defaults to 'AccuracyTableGeneratorDefaults.xml'
function save_params(h)

defSimParams = [];
defSimParams.simulatorParamsFile =  h.simulatorParamsFile.String;
for i=1:length(h.config)
    defSimParams.(['simConfig' num2str(i)]).active = logical(h.config(i).checkbox.Value);
    defSimParams.(['simConfig' num2str(i)]).name = h.config(i).name_edit.String;
    
    code_popup_val = h.config(i).code_popup.Value;
    defSimParams.(['simConfig' num2str(i)]).txCode = h.config(i).code_popup.String{code_popup_val};
    
    defSimParams.(['simConfig' num2str(i)]).nav = str2double(h.config(i).nav_edit.String);
    defSimParams.(['simConfig' num2str(i)]).tx_f = h.config(i).tx_f_popup.String{h.config(i).tx_f_popup.Value};
    defSimParams.(['simConfig' num2str(i)]).rx_f = h.config(i).rx_f_popup.String{h.config(i).rx_f_popup.Value};
end


struct2xmlWrapper(defSimParams,'AccuracyTableGeneratorDefaults.xml');
end




%set_watches_wrapper([figure_handle],[BOOL])
function set_watches_wrapper(h,mode)

set_watches(h.f,mode);
if( mode == true )
    for i=1:length(h.config)
        checkbox_callback(h.config(i).checkbox,[],i);
        
    end
end
end




%draw uitable func
function [datac,rnames,cnames] = draw_ui_table(accTable, dists,pc)


%resize the table size to the non nan elemants
okRow = any(~isnan(accTable),2);
okRow(1) = true; %do not remove first row
okRow(find(~okRow,1))=true; %add last row,even though bad

accTable = accTable(okRow,:);
dists = dists(okRow);

datac = arrayfun(@(x) round(x*100)/100,accTable,'uni',false);
datac(isnan(accTable)) = arrayfun(@(x) '-',1:(nnz(isnan(accTable))),'uni',false);


%draw the table
tbl_h = 440;
tbl_w = 1050;
if(isvector(accTable))
    tbl_h = 60;
    tbl_w = 300;
end
ff=figure('units','pixels','position',[0 0 tbl_w tbl_h],'menubar','none','toolbar','none','numberTitle','off','name','Accuarcy results','resize','on');

rnames = arrayfun(@(x) sprintf('%d',x),dists,'uni',false);


cnames = {pc.name};
tblH=uitable(ff,'ColumnName',cnames,'RowName',rnames,'data',datac,'units','normalized','position',[0 0 1 1]);
set(tblH,'units','pixels');
tblSz = get(tblH,'position');
set(ff,'position',tblSz);
centerfig(ff);


end




%write to .xls and plot results (only for table button)
function xls_and_plot(pc, rnames,cnames,datac,dists,accTable,save_file)

%%%plot
fh=figure;
figure(fh);
a=plot(dists,accTable,'linewidth',2);
c = lines(length(pc)/2);
for i=1:length(pc)/2
    a(2*i-1).Color = c(i,:);
    a(2*i-0).Color = a(2*i-1).Color;
    a(2*i-1).LineStyle='-';
    a(2*i-0).LineStyle='--';
end
grid on
legend({pc.name});
xlabel('Distance[mm]');
ylabel('Accuracy[mm]');



%%%xls write

%write paramas to worksheets
for i=1:length(pc)
    [~,~] = xlswrite(save_file,celltblRec(pc(i)) ,sprintf('SETTING%d',i));
end

%builds the table of res
xls_table = cell(1+length(rnames),1+length(pc));
xls_table(1,2:end) = cnames;
xls_table(2:end,1) = rnames;
xls_table(2:end,2:end) = datac;

[status,message] = xlswrite(save_file, xls_table,'AccuracyTable');

%warning massage from xls
if(status == 0)
    w = warndlg(message.message);
    set_watches_wrapper(fh,false);
    drawnow;
    waitfor(w);
end

end




%builds the settings table for the .xls
function c=celltblRec(p)
c={};
fn = fieldnames(p);

for i=1:length(fn)
    c{end+1,1}=fn{i};%#ok
    if(isstruct(p.(fn{i})))
        
        cc = celltblRec(p.(fn{i}));
        newc = cell(size(c,1)+size(cc,1),max(size(c,2),2+size(cc,2)-1));
        newc(1:size(c,1),1:size(c,2))=c;
        newc(size(c,1)+1:end,2:end)=cc;
        c = newc;
    else
        c{end,2} = p.(fn{i});
        
    end
    
    
end

end





