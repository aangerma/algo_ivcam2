clear;
sz = [24 32];
% params.model = '+dataGen\+Shapes\flat.stl';
params.model=dataGen.generateRandomSecene(1);
params.prjector.kMat=[2 0 0; 0 2.666 0 ; 0 0 1];
params.prjector.rMat=eye(3);
params.prjector.res=sz;
params.prjector.power = 400;%mW
params.sensor.tMat=zeros(3,1);
params.verbose = 1;
params.system_dt = 0.001;
params.scenario.dt=1;%nsec

tw=16;
tw1=ones(1,tw);
tw0=zeros(1,tw);
%ambient
params.scenario.data{1}.pat=zeros([sz 1]);
params.scenario.data{1}.txmod = [0 tw0 0];
params.scenario.data{1}.rxmod = [0 tw1 0];

%albedo
 P=rand([sz 96*2])>.5;
%     P = reshape(eye(prod(sz)),sz(1),sz(2),[])>0;
params.scenario.data{2}.pat=P;
params.scenario.data{2}.txmod = [0 tw1 tw1 0 ];
params.scenario.data{2}.rxmod = [0 tw0 tw1 0 ];

%depth
params.scenario.data{3}.pat=P;
params.scenario.data{3}.txmod = [0 tw1 0];
params.scenario.data{3}.rxmod = [0 tw1 0];

%sensor
params.sensor.sampler.nbits=12;
params.sensor.sampler.v0 = 0;     %v
params.sensor.sampler.v1 = 1e-3; %v
params.sensor.collectionArea = 1;%mm^2
fprintf('Compression ratio: 1:%d\n',prod(sz)/size(P,3));
%% run sim
[mes,gt]=Sim.run(params);
% mes = cellfun(@(x) double(x)./(2.^params.sensor.sampler.nbits-1)*(params.sensor.sampler.v1-params.sensor.sampler.v0)+params.sensor.sampler.v0,mes,'uni',0);
% mes = round(mes*2^params.sensor.sampler.nbits)/2^params.sensor.sampler.nbits;
%% solve
Solver.run(mes,gt,params);

