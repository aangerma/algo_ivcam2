function simRunner(defSimParamsVal)
h.N = 6;

h.rnames.osnr_tp1             = 'OSNR[db]';
h.rnames.range                = 'Measured range[mm]';
h.rnames.acc                  = 'Depth accuarcy[mm]';
h.rnames.opticalOutputPowerDCRMS = 'Optical output power(RMS)[mW]';
h.rnames.opticalOutputPowerP2P   = 'Optical output power(P2P)[mW]';

h.rnames.opticalInputPowerDCRMS = 'Optical input power(RMS)[mW]';
h.rnames.opticalInputPowerP2P   = 'Optical input power(P2P)[mW]';

h.rnames.apdNEP                 = 'APD NEP                [mW]';
h.rnames.apdOutputCurrentDCRMS  = 'APD output current(RMS)[mA]';
h.rnames.apdOutputCurrentACRMS  = 'APD output current(STD)[mA]';
h.rnames.apdOutputCurrentP2P    = 'APD output current(P2P)[mA]';

h.rnames.tiaPreAmpIRN           = 'TIA (preamp) IRN       [mA]';
h.rnames.tiaOutputVoltageDCRMS  = 'TIA output voltage(RMS)[mV]';
h.rnames.tiaOutputVoltageACRMS  = 'TIA output voltage(STD)[mV]';
h.rnames.tiaOutputVoltageP2P    = 'TIA output voltage(P2P)[mV]';

h.rnames.hpfOutputVoltageDCRMS  = 'HPF output voltage(RMS)[mV]';
h.rnames.hpfOutputVoltageACRMS  = 'HPF output voltage(STD)[mV]';
h.rnames.hpfOutputVoltageP2P    = 'HPF output voltage(P2P)[mV]';

if(~exist('defSimParamsVal','var'))
        defSimParamsVal = cell(h.N,1);
    defSimParamsVal{1} = '\\invcam322\ohad\data\lidar\simulatorParams\params_860SKU1_indoor.xml';
end
defDetectorParamsFile = '\\invcam322\ohad\data\lidar\simulatorParams\detector\sequenceDetectorParams.xml';
h.rH = 20;
winH = 700;
winW = 900;
h.f = figure('units','pixels','position',[0 0 winW winH],'menubar','none','toolbar','none','numberTitle','off','name','LIDAR simulator runner','resize','off','userdata','structGUI');
centerfig(h.f);

uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*2 200 h.rH],'string','Detector parameters file name','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
h.detectorParmsFile=uicontrol('Style','edit','parent',h.f,'units','pixels'      ,'pos',[205 winH-h.rH*2 winW-210-h.rH h.rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',defDetectorParamsFile);
uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[winW-5-h.rH winH-h.rH*2 h.rH h.rH],'callback',{@callback_selectFile,h.detectorParmsFile},'string','...');
edtImg = 1-padarray(str2img('E'),[2 2],0 ,'both');
edtImg(edtImg==1)=nan;
edtImg = cat(3,edtImg,edtImg,edtImg);
for i=1:h.N
    uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*(i+2) 200 h.rH],'string',sprintf('Sim config file scenario #%d',i),'horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
    h.simParamsFile(i)=uicontrol('Style','edit','parent',h.f,'units','pixels'      ,'pos',[205 winH-h.rH*(i+2) winW-210-2*h.rH h.rH],'horizontalAlignment','left','fontsize',10,'backgroundcolor','w','userdata','*.xml','string',defSimParamsVal{i});
    uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[winW-5-2*h.rH winH-h.rH*(i+2) h.rH h.rH],'callback',{@callback_selectFile,h.simParamsFile(i)},'string','...');
    uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[winW-5-h.rH winH-h.rH*(i+2) h.rH h.rH],'callback',{@callback_editFile,h.simParamsFile(i)},'cdata',edtImg);
end

colW = round((winW-30)/(h.N+1));

uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*(h.N+4) colW h.rH],'string','Distance[mm]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*(h.N+5) colW h.rH],'string','Albedo[0-1]','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*(h.N+6) colW h.rH],'string','Display','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));
uicontrol('Style','text','parent',h.f,'units','pixels'      ,'pos',[5   winH-h.rH*(h.N+7) colW h.rH],'string','Run','horizontalAlignment','left','fontsize',10,'backgroundcolor',get(h.f,'color'));

for i=1:h.N
    h.distance(i)=uicontrol('Style','edit','parent',h.f,'units','pixels'      ,'pos',[15+colW*i winH-h.rH*(h.N+4) colW h.rH],'horizontalAlignment','center','fontsize',10,'backgroundcolor','w','string','1000');
    h.albedo(i)  =uicontrol('Style','edit','parent',h.f,'units','pixels'      ,'pos',[15+colW*i winH-h.rH*(h.N+5) colW h.rH],'horizontalAlignment','center','fontsize',10,'backgroundcolor','w','string','1');
    h.display(i)  =uicontrol('Style','checkbox','parent',h.f,'units','pixels'      ,'pos',[5+colW*i+colW/2 winH-h.rH*(h.N+6) colW h.rH],'value',0);
    h.doRun(i)  = uicontrol('Style','checkbox','parent',h.f,'units','pixels'      ,'pos',[5+colW*i+colW/2 winH-h.rH*(h.N+7) colW h.rH],'value',1);
    
end
uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[5 winH-h.rH*(h.N+9) colW h.rH*2],'callback',@callback_run,'string','Run');
uicontrol('style','pushbutton','parent',h.f,'units','pixels','pos',[5+colW winH-h.rH*(h.N+9) colW h.rH*2],'callback',@callback_run_max_range,'string','Range simulation');


guidata(h.f,h);
updateTable(h,nan(length(struct2cell(h.rnames)),h.N));
end
function callback_run_max_range(varargin)
h = guidata(varargin{1});
set_watches(h.f,false);
detectorParmsFile=h.detectorParmsFile.String;
if(~exist(detectorParmsFile','file'))
    warndlg('detector param file not found');
    
    set_watches(h.f,true);
    return
end
trgtAcc = 20;
dsample = 10;
sampleRs = Utils.dtnsec2rmm(0.2);
dists = 50:dsample:8000;
dists = [50 250 500 800 1000 1200 1500:500:5000];
accTable = nan(length(dists),h.N);
prcTable = nan(length(dists),h.N);

for i=1:h.N
    
    rngSave = str2double(h.distance(i).String);
    Hbar = waitbar(0,sprintf('running range simulation %d/%d',i,h.N));
    for j=1:length(dists)
        
        waitbar(j/length(accTable),Hbar,sprintf('%4d%%',round(j/length(accTable)*100)));
        h.distance(i).String = num2str(dists(j));
        
        res = runSingle(h,i);
        if(isempty(res))
            break;
        end
        if(dists(j)>400 && res.acc>trgtAcc)
            break;
        end
        if(res.acc<trgtAcc)
            accTable(j,i)=res.acc;
            prcTable(j,i)=res.dprec;
        end
    end
    close(Hbar);
    h.distance(i).String = num2str(rngSave);
    
end
cnames = tableRowNames(h);
save dbg
%%
load dbg
dists4disp = [50 250 500 800 1000 1200 1500:500:5000];

maxRngInd = arrayfun(@(i) find([1;~isnan(accTable(:,i))],1,'last')-1,1:h.N);
maxRngInd(maxRngInd==0)=1;
referenceRange = 1000;

dprc = bsxfun(@minus,prcTable,nanmedian(prcTable));
winSz = ceil(sampleRs/dsample);

minFeture = abs(dprc) +accTable;

for i=1:length(dists)
    ind = max(1,i-winSz):min(length(dists),i+winSz);
    accTable2(i,:)=nanmax(accTable(ind,:));
    dprc2(i,:)=nanmax(dprc(ind,:));
    minFeture2(i,:)=nanmax(minFeture(ind,:));
end
% accTable = accTable2;
refRngAcc = interp1(dists,accTable,referenceRange);
rnames = ['Single pixel max range','Single pixel accuracy @max range',sprintf('Single pixel accuracy @%gm',referenceRange/1000),' ',arrayfun(@(x) sprintf('%d',x),dists4disp,'uni',false)];




tbl4disp = [dists(maxRngInd);...
    accTable(sub2ind(size(accTable),maxRngInd,1:h.N));...
    refRngAcc;...
    nan(1,h.N);...
    interp1(dists,accTable, dists4disp   )];
datac = arrayfun(@(x) round(x*100)/100,tbl4disp,'uni',false);
datac(isnan(tbl4disp)) = arrayfun(@(x) '',1:(nnz(isnan(tbl4disp))),'uni',false);

ff=figure('units','pixels','position',[0 0 750 350],'menubar','none','toolbar','none','numberTitle','off','name','Accuarcy results','resize','off');
centerfig(ff);
uitable(ff,'ColumnName',cnames,'RowName',rnames,'data',datac,'units','normalized','position',[0 0 1 1]);


f=figure;


subplot(3,1,1,'parent',f);
plot(dists,accTable);
xlabel('distance [mm]');
ylabel('accuarcy[mm]');
grid minor
axis tight

subplot(3,1,2,'parent',f);
plot(dists,dprc);
xlabel('distance [mm]');
ylabel('\Delta precision[mm]');
axis tight
set(gca,'ylim',[-20 20]);
grid minor

subplot(3,1,3,'parent',f);
plot(dists,minFeture2);
xlabel('distance [mm]');
ylabel('Minimum feature[mm]');
grid minor
axis tight
set(gca,'ylim',[0 20]);


set_watches(h.f,true);
legend(cnames);


end


function callback_run(varargin)
h = guidata(varargin{1});
set_watches(h.f,false);
detectorParmsFile=h.detectorParmsFile.String;
if(~exist(detectorParmsFile','file'))
    warndlg('detector param file not found');
    
    set_watches(h.f,true);
    return
end
ff = fieldnames(h.rnames);
data =nan(length(ff),h.N);
for i=1:h.N
    res = runSingle(h,i);
    if(isempty(res))
        continue;
    end
    for j=1:length(ff)
        data(j,i)=res.(ff{j});
    end
    updateTable(h,data);
    drawnow;
    
end
set_watches(h.f,true);
end

function res = runSingle(h,i)
res=[];
detectorParmsFile=h.detectorParmsFile.String;
simParamsFn = h.simParamsFile(i).String;
if(h.doRun(i).Value==0)
    return;
end
if(isempty(simParamsFn) || exist(simParamsFn,'file')~=2)
    return;
end
distance = str2double(h.distance(i).String);
if(isnan(distance))
    return;
end
albedo = str2double(h.albedo(i).String);
if(isnan(albedo))
    return;
end
verbose = h.display(i).Value;
t=tic;
res = runSim(simParamsFn,detectorParmsFile,distance,albedo,verbose,i);
res.runTime = toc(t);
end

function res = runSim(simParamsFn,detectorParmsFile,distance,albedo,verbose,i)

nMes = 100;
outliersP = 0.1;
simParams = xml2structWrapper(simParamsFn);
simParams.runTime= (length(simParams.laser.txSequence)/simParams.laser.frequency+simParams.laser.txQuietHeadTime)*(nMes+1);
simParams.verbose = false;
seqDetectorParams = xml2structWrapper(detectorParmsFile);

seqDetectorParams.verbose = false;
seqDetectorParams.ker = simParams.laser.txSequence*2-1;
model =struct('t',[0 simParams.runTime],'r',[ distance  distance],'a',[ albedo albedo ]);

if(verbose)
    figure('name',sprintf('Scenario %d',i));
end


    %

    rng(1);
    if(verbose)
        simParams.verbose = 2;
        subplot(211)
    end
    [chA,~,txTimes,res] = Simulator.runSim(model,simParams);
    
    seqDetectorParamsI=seqDetectorParams;
    seqDetectorParamsI.txTimes = txTimes;
    if(verbose)
        seqDetectorParamsI.verbose = 2;
        subplot(212)
    end
    peaks_hat = Utils.sequenceDetector(chA(:,1),chA(:,2),seqDetectorParamsI);
    
    dt = (peaks_hat-txTimes);
    dt(1)=[];%remove due to highpass
    r_ = Utils.dtnsec2rmm(dt);




res.acc  = nan;

rLen = length(r_);
nOutlier = ceil(rLen*outliersP);
nInf = nnz(isinf(r_));

r_(isinf(r_))=[];
outlierP2 = (nOutlier-nInf)/rLen;
if(outlierP2>0 && outlierP2<1)
    dlims = prctile(r_,[outlierP2/2 1-outlierP2/2]*100);
    r_=r_(r_>=dlims(1) & r_<=dlims(2));
else
    r_=nan;
end
stdr=std(r_);
mnr = mean(r_);


res.acc = stdr;
res.dprec = mnr-distance;
res.range = round(mnr);
end

function cnames = tableRowNames(h)
cnames = cell(1,h.N);
for i=1:h.N
    cnames{i} = sprintf('Scenario %d',i);
    if(isempty(h.simParamsFile(i).String) || exist(h.simParamsFile(i).String,'file')~=2)
        continue;
    end
    p = xml2structWrapper(h.simParamsFile(i).String);
    if(~isfield(p,'name'))
        continue;
    end
    cnames{i} = p.name;
end
end

function updateTable(h,data)

% colorCell = @(c,v) ['<html><table border=0 width=50 bgcolor=#',reshape(dec2hex(floor(c*255),2)',[],6),'><TR><TD  align="right">',num2str(v),'</TD></TR> </table></html>'];

p = get(h.f,'position');
winH = p(4);
winW = p(3);
tblTopY = h.rH*(h.N+10)-5;
cnames = tableRowNames(h);



datac = arrayfun(@(x) x,data,'uni',false);
datac(isnan(data)) = arrayfun(@(x) '',1:(nnz(isnan(data))),'uni',false);
h.t = uitable(h.f,'ColumnName',cnames,'RowName',struct2cell(h.rnames),'data',datac,'units','pixels','position',[5 5 winW-10 winH-tblTopY],'FontSize',12);
set(h.t,'columnWidth',{round((winW-350)/(h.N))});





end
function callback_selectFile(varargin)
t=get(varargin{3},'userdata');
if(isempty(t))
    d = uigetdir(get(varargin{3},'string'));
    f='/';
else
    [f,d]=uigetfile(t);
    
end
if(d~=0)
    set(varargin{3},'string',[d f]);
end
end

function callback_editFile(varargin)
xmlfn = get(varargin{3},'string');
if(isempty(xmlfn))
    return;
end
system(sprintf('start %s',xmlfn));
end

