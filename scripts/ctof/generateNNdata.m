clear;
outputfldr = '\\algonas\Root\Data\cToF\simData2';
mkdirSafe(outputfldr);
paramsfn = fullfile(outputfldr,filesep,'params.mat');
if(exist(paramsfn,'file'))
    load(paramsfn);
else
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
    rng(1);
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
    save(paramsfn,'params');
end
%%
N_SAMPLES_PER_BATCH=1e2;
cnt = 0;
while(true)
    fn = sprintf('%s\\simdata_%06d.bin',outputfldr,cnt);
    
    
    if(~exist(fn,'file'))
        fid=fopen(fn,'w');
        
        for i=1:N_SAMPLES_PER_BATCH
            tt= tic;
            randseed = (cnt*N_SAMPLES_PER_BATCH+i-1);
            params.model=dataGen.generateRandomSecene(randseed);
            [mes,gt]=Sim.run(params);
            mesv=single([mes{1} vec([mes{2};mes{3}])']);
            fwrite(fid,typecast([single([mes{:}]) single([gt.rtdS(:);gt.a(:)])'],'uint32'),'uint32');
            tt=toc(tt);
            fprintf('Done(%4d sec) %5d %4d/%4d\n',round(tt),cnt,i,N_SAMPLES_PER_BATCH)
        end
        fclose(fid);
        
    end
    cnt=cnt+1;
end


% fid = fopen(fullfile(outputfldr,filesep,'ctofNNdata.cfg'),'w');
% fprintf(fid,'[data]\nnfeatures=%d\nheight=%d\nwidth=%d',length([mes{:}]),sz);
% fclose(fid);