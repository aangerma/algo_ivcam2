% Load data

ref.eGeom = 1.1;
ref.Ldd = 60.39;
ref.ma = 46.23;
ref.mc = 50.92;
ref.tsense = 385.37;
ref.vsense = 374.16;
ref.vBias = [1.638,2.299,2.012];
ref.iBias = [0.000482,0.000513,0.000603];
ref.rBias = ref.vBias./ref.iBias;



dataDir = "X:\Users\tmund\pzrThermalDebug";
for i = 1:6 % :11
    fn = fullfile(dataDir,['data',num2str(i),'.mat']);
    d = load(fn);
    data(i) = d.data;
end
%% Stage 1: Show eGeom as a function of temperature for all possible indicators. Mark the calibration value.
showEGeomPerIndicator(data,ref);
%% Stage 3: Apply fix given vBias1+3 for x, vBias2 for y, ldd for APD.
fixes = calcFix(data(1),ref); 
%% Stage 4: Send mail with description to Yoni Golan


%%

