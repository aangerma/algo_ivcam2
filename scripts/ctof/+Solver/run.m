function run(mes,gt,params)
%% reconstruct
%init guess
% rtd_hat=1000*ones(sz);
rtd_hat = gt.rtdS;
a_hat = gt.a;
sz = params.prjector.res;
nItr = 1;
    o = Solver.genDict(sz);
    %%
for i=1:nItr
    %%
    
    p=params.prjector.power/(prod(sz));

    % gamma (ambient)
    collectionT = nnz(params.scenario.data{1}.rxmod)*params.scenario.dt;
    g = mes{1}/collectionT;
    % intensity
    %%
    collectionT = sum(params.scenario.data{2}.rxmod)*params.scenario.dt;
    matB=(mes{2}-g*collectionT)/(collectionT*p);
    
    rangeE =min(1,params.sensor.collectionArea./(pi*(rtd_hat).^2));
    matA  = double(reshape(params.scenario.data{2}.pat.*rangeE,prod(sz),[])');
    matA = matA*1e9;%compensate on quantization
    a_hat=admm(matB,o,matA,1e-3,0,1e-3,1,false);
    a_hat = reshape(a_hat,sz);
%     imagesc(a_hat);
    
%     imagesc(reshape(pinv(matA)*matB,sz))
%     imagesc(reshape(mes{2}/(2^12-1),sz)/(p*tw).*(pi*gt.rtdS.^2))%check measurments
%     on identity prjection
    
    %%
    % depth
    collectionT = nnz(params.scenario.data{3}.rxmod)*params.scenario.dt;
    
    
    matB = (mes{2}-mes{3})/p;
    pat_ = params.scenario.data{3}.pat.*a_hat;
    matA = double(reshape(pat_,prod(sz),[])');
    gamma_hat=admm(matB,o,matA,1e-4,0,1e-1,1,false);
    
    scaleFact = mean(vec((gt.rtdS./rtd_hat)));
    rtd_hat = reshape(1./gamma_hat,sz)*C()*scaleFact;
    
    
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

end