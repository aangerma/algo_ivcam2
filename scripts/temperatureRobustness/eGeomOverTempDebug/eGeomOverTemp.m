% Load data

% ref.eGeom = 1.1;
% ref.Ldd = 60.39;
% ref.ma = 46.23;
% ref.mc = 50.92;
% ref.tsense = 385.37;
% ref.vsense = 374.16;
% ref.vBias = [1.638,2.299,2.012];
% ref.iBias = [0.000482,0.000513,0.000603];
% ref.rBias = ref.vBias./ref.iBias;

load("X:\Users\tmund\pzrThermalDebug\data.mat");
load("X:\Users\tmund\pzrThermalDebug\framesData.mat");
data.framesData = framesData;
load("X:\Users\tmund\pzrThermalDebug308\data01.mat");
load("X:\Users\tmund\pzrThermalDebug\data03.mat");
load("X:\Users\tmund\pzrThermalDebug65\data02.mat");
ref.eGeom = 1.5;
ref.Ldd = 63; %data.regs.FRMW.dfzCalTmp;
ref.ma = 0;
ref.mc = 0;
ref.tsense = 0;
ref.vsense = 0;
ref.vBias = data.regs.FRMW.dfzVbias';%[1.704,2.146,2.318];
ref.iBias = data.regs.FRMW.dfzIbias';
ref.rBias = ref.vBias./ref.iBias;
ref.apdTmptr = 50.74; % unit 65;
dataDir = "X:\Users\tmund\pzrThermalDebug\old";
dataDir = 'X:\Users\tmund\pzrThermalDebug';
for i = 1:1 % :11
    fn = fullfile(dataDir,['data0',num2str(i),'.mat']);
    d = load(fn);
    data(i) = d.data;
end

%% Fix data
fwPath = 'C:\temp\unitCalib\F9090065\PC26\AlgoInternal';
fwPath = 'C:\temp\unitCalib\F9090308\PC03\AlgoInternal';
fw = Pipe.loadFirmware(fwPath);
regs = fw.get();

% for i = 1:numel(data.framesData)
%     [data.framesData(i).ptsWithZ(:,2) ,data.framesData(i).ptsWithZ(:,3)] = Calibration.Undist.inversePolyUndistAndPitchFix(data.framesData(i).ptsWithZ(:,2) ,data.framesData(i).ptsWithZ(:,3),regs);
% end

%% Stage 1: Show eGeom as a function of temperature for all possible indicators. Mark the calibration value.
for i = 1:numel(data.framesData)
    valids(i) = ~isempty(data.framesData(i).ptsWithZ);
%     [data.framesData(i).eGeom, e2, e3,errors] = Validation.aux.gridError(data.framesData(i).ptsWithZ, [9,13], 30);
    
end
data.framesData = data.framesData(valids);

for i = 1:numel(data.framesData)
    
    [data.framesData(i).eGeom, e2, e3,errors] = Validation.aux.gridError(data.framesData(i).ptsWithZ(:,6:8), [9,13], 30);
%     v = data.framesData(i).ptsWithZ(:,6:8);
%     v = reshape(v,20,28,3);
%     rows = find(any(~isnan(v(:,:,1)),2));
%     cols = find(any(~isnan(v(:,:,1)),1));
%     grd = [numel(rows),numel(cols)];
%     v = reshape(v(rows,cols,:),[],3);
%     [data.framesData(i).eGeom, e2, e3,errors] = Validation.aux.gridError(v, grd, 30);
    
end
showEGeomPerIndicator(data,ref);
%% Stage 3: Apply fix given vBias1+3 for x, vBias2 for y, ldd for APD.
fixes = calcFix(data(1),ref); 
dataFixed = applyFix(data(1),ref,fixes,regs);

showEGeomPerIndicator(dataFixed,ref);

%% Stage 4: Send mail with description to Yoni Golan


%%

