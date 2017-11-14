clear;
params.modelFn = 'flat.stl';
params.prjector.kMat=[2 0 0; 0 2.666 0 ; 0 0 1];
params.prjector.rMat=eye(3);
params.prjector.res=[32 32];
params.prjector.power = 400e-3;%W
params.sensor.tMat=zeros(3,1);
params.verbose = 1;
params.system_dt = 0.001;
params.scenario.dt=1;%nsec

tw=20;
tw1=ones(1,16);
tw0=zeros(1,16);
%ambient
params.scenario.data{1}.pat=zeros([params.prjector.res 1]);
params.scenario.data{1}.txmod = [0 tw0 0];
params.scenario.data{1}.rxmod = [0 tw1 0];

%albedo
% P=rand([params.prjector.res 1024])>.5;
     P = reshape(eye(prod(params.prjector.res)),params.prjector.res(1),params.prjector.res(2),[])>0;
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
params.sensor.sampler.v1 = 20e-3; %v
params.sensor.collectionArea = 1;%mm^2
fprintf('Compression ratio: 1:%d\n',prod(params.prjector.res)/size(P,3));
%% run sim
[mes,gt]=runSim(params);
mes = cellfun(@(x) double(x)./(2.^params.sensor.sampler.nbits-1)*(params.sensor.sampler.v1-params.sensor.sampler.v0)+params.sensor.sampler.v0,mes,'uni',0);
% mes = round(mes*2^params.sensor.sampler.nbits)/2^params.sensor.sampler.nbits;
%% reconstruct
%init guess
% rtd_hat=1000*ones(params.prjector.res);
rtd_hat = gt.rtdS;
a_hat = gt.a;
nItr = 1;
    o = genDict(params.prjector.res);
    %%
for i=1:nItr
    %%
    
    p=params.prjector.power/(prod(params.prjector.res));

    % gamma (ambient)
    collectionT = nnz(params.scenario.data{1}.rxmod)*params.scenario.dt;
    g = mes{1}/collectionT;
    % intensity
    %%
    collectionT = nnz(params.scenario.data{2}.rxmod)*params.scenario.dt;
    matB=(mes{2}-g*collectionT)/(collectionT*p);
    rangeE = min(1,params.sensor.collectionArea./(2*pi*(rtd_hat*1e-3).^2));
    matA  = double(reshape(params.scenario.data{2}.pat.*rangeE,prod(params.prjector.res),[])');
    a_hat=admm(matB,o,matA,1e-5,0,1e-3,1,false);
    a_hat = reshape(a_hat,params.prjector.res);
    %%
    % depth
    collectionT = nnz(params.scenario.data{3}.rxmod)*params.scenario.dt;
    
    
    matB = (mes{2}-mes{3})/p;
    pat_ = params.scenario.data{3}.pat.*gt.a;
    matA = double(reshape(pat_,prod(params.prjector.res),[])');
    rtd_hat=admm(matB,o,matA,1e-4,0,1e-1,1,false);
    rtd_hat = reshape(rtd_hat,params.prjector.res)*C();
    
    
    %Display results
    
    errMsk = pad_array(ones(size(gt.rtdS)-2),[1 1],'both').*~isinf(gt.rtdS);
    figure(1);
    subplot(2,3,1);
    imagesc(gt.a);title('Abedo(GT)');colorbar;axis image
    subplot(2,3,2);
    imagesc(a_hat);title('Abedo(reconst)');colorbar;axis image
    subplot(2,3,3);
    imagesc(abs(gt.a-a_hat).*errMsk);title('Abedo(err)');colorbar;axis image
    subplot(2,3,4);
    imagesc(gt.rtdS);title('RTD(GT)');colorbar;axis image
    subplot(2,3,5);
    imagesc(rtd_hat);title('RTD(reconst)');colorbar;axis image
    subplot(2,3,6);
    imagesc(abs(gt.rtdS-rtd_hat).*errMsk);title('RTD(err)');colorbar;axis image
    
    v_hat=cloudFromR(rtd_hat,params.prjector.kMat);
    v_=cloudFromR(gt.rtdS,params.prjector.kMat);
    
    %
    figure(2);
    clf
    ah(1)=subaxis(1,2,1);
    surface(v_(:,:,1),v_(:,:,2),v_(:,:,3),gt.a,'parent',ah(1));
    grid on;axis equal
    title('Ground truth');
    ah(2)=subaxis(1,2,2);
    grid on;axis equal
    surface(v_hat(:,:,1),v_hat(:,:,2),v_hat(:,:,3),a_hat,'parent',ah(2));
    title('Reconstruction');
    setprop = @(prop) set(ah,prop,minmax(vec(cell2mat(get(ah,prop)))));
    setprop('xlim');setprop('ylim');setprop('zlim');
    linkprop(ah,{'CameraPosition','CameraTarget','CameraUpVector','xlim','ylim','zlim'});
    view([18 25])
    
end
% imagesc([normByMax(z) normByMax(gt.a)])
