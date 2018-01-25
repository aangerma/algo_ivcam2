clear;
N_SAMPLES_PER_BATCH=1e2;
sz = [24 32];
% params.model = '+dataGen\+Shapes\flat.stl';

params.prjector.kMat=[2 0 0; 0 2.666 0 ; 0 0 1];
params.prjector.rMat=eye(3);
params.prjector.res=sz;
params.prjector.power = 400;%mW
params.sensor.tMat=zeros(3,1);
params.verbose = 0;
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
P=randn([sz prod(sz)])>0;
%     P = reshape(eye(prod(sz)),sz(1),sz(2),[])>0;
params.scenario.data{2}.pat=P;
params.scenario.data{2}.txmod = [0 tw1 tw1 0 ];
params.scenario.data{2}.rxmod = [0 tw0 tw1 0 ];

%depth
params.scenario.data{3}.pat=P;
params.scenario.data{3}.txmod = [0 tw1 0];
params.scenario.data{3}.rxmod = [0 tw1 0];

%sensor
params.sensor.sampler.nbits=16;
params.sensor.sampler.v0 = 0;     %v
params.sensor.sampler.v1 = 1e-3; %v
params.sensor.collectionArea = 1;%mm^2

%%
outputfldr = '\\algonas\Root\Data\cToF\simData';
cnt = 0;
while(true)
    ifn = sprintf('%s\\simdataI_%06d.bin',outputfldr,cnt);
    ofn = sprintf('%s\\simdataO_%06d.bin',outputfldr,cnt);
    
    if(~exist(ifn,'file'))
        fidi=fopen(ifn,'w');
        fido=fopen(ofn,'w');
        for i=1:N_SAMPLES_PER_BATCH
            tt= tic;
            randseed = (cnt*N_SAMPLES_PER_BATCH+i-1);
            params.model=dataGen.generateRandomSecene(randseed);
            [mes,gt]=Sim.run(params);
            mesv=single([mes{1} vec([mes{2};mes{3}])']);
            fwrite(fidi,typecast(mesv,'uint32'),'uint32');
            fwrite(fido,typecast(single([gt.rtdS(:);gt.a(:)])','uint32'),'uint32');
            tt=toc(tt);
            fprintf('Done(%4d sec) %5d %4d/%4d\n',round(tt),cnt,i,N_SAMPLES_PER_BATCH)
        end
        fclose(fidi);
        fclose(fido);
        
    end
    cnt=cnt+1;
end


% fid = fopen(fullfile(outputfldr,filesep,'ctofNNdata.cfg'),'w');
% fprintf(fid,'[data]\nnfeatures=%d\nheight=%d\nwidth=%d',length([mes{:}]),sz);
% fclose(fid);