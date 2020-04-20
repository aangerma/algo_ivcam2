% dataPath = 'C:\Users\mkiperwa\Downloads\movies\results\continous\depthScale\sameAugSameScene4\fxfyTfull\results_04-02-2020 12-37.mat';
dataPath = "C:\Users\mkiperwa\Downloads\movies\results\continous\depthScale\25_3_20_F9440687_SnapshotsLongRange_768X1024_RGB_1920X1080\sameAugSameScene4\fxfyOxOyRT\results_04-07-2020 13-30.mat";

load(dataPath);

figure; subplot(3,4,1);plot(1:numel([currentResults.uvErrPre]),[currentResults.uvErrPre]);
hold on; plot(1:numel([currentResults.uvErrPostPOpt]),[currentResults.uvErrPostPOpt]);
hold on; plot(1:numel([currentResults.uvErrPostKRTOpt]),[currentResults.uvErrPostKRTOpt]);
hold on; plot(1:numel([currentResults.uvErrPostKdepthRTOpt]),[currentResults.uvErrPostKdepthRTOpt],'--');
legend('uvErrPre','uvErrPostPOpt','uvErrPostKRTOpt','uvErrPostKdepthRTOpt'); grid minor;
ylabel('UV mapping error [RGB res]');
title('UV Mapping Error Comparison');

a = [currentResults.gidPre];
subplot(3,4,2);plot(1:numel(a),a);hold on;
a = [currentResults.gidPostKdepthRTOpt];
plot(1:numel(a),a,'--');
legend('GID Pre Opt','GID Post Opt'); grid minor;
ylabel('Error');
title('GID Error Before and After Optimization');
%%
newT = zeros(numel(currentResults),3);
newRang = zeros(numel(currentResults),3);
KdepthNew = zeros(numel(currentResults),4);
Pnew = zeros(numel(currentResults),3,4);
PnewFromDepth = zeros(numel(currentResults),3,4);
for k = 1:numel(currentResults)
    newT(k,:) = currentResults(k).newParamsKdepthRT.Trgb'; 
    [newRang(k,1),newRang(k,2),newRang(k,3)] = OnlineCalibration.aux.extractAnglesFromRotMat(currentResults(k).newParamsKdepthRT.Rrgb);
    Knew = currentResults(k).newParamsKdepthRT.Kdepth;
    KdepthNew(k,1) = Knew(1,1);
    KdepthNew(k,2) = Knew(2,2);
    KdepthNew(k,3) = Knew(1,3);
    KdepthNew(k,4) = Knew(2,3);
    Pnew(k,:,:) = currentResults(k).newParamsP.rgbPmat;
    PnewFromDepth(k,:,:) = currentResults(k).newParamsKrgbRT.rgbPmat;
end
%%
subplot(3,4,3); plot(1:numel(currentResults),newT(:,1));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Trgb(1),numel(currentResults)),'--');
legend('newTx','originalTx'); grid minor;
title('Translation Matrix Change');


subplot(3,4,4); plot(1:numel(currentResults),newT(:,2));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Trgb(2),numel(currentResults)),'--');
legend('newTy','originalTy'); grid minor;
title('Translation Matrix Change');


subplot(3,4,5); plot(1:numel(currentResults),newT(:,3));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Trgb(3),numel(currentResults)),'--');
legend('newTz','originalTz'); grid minor;
title('Translation Matrix Change');

[origRalpha,origRbeta,origRgamma] = OnlineCalibration.aux.extractAnglesFromRotMat(currentResults(k).originalParams.Rrgb);
subplot(3,4,6); plot(1:numel(currentResults),newRang(:,1).*180./pi());
hold on; plot(1:numel(currentResults),repelem(origRalpha.*180./pi(),numel(currentResults)),'--');grid minor;
legend('newRxAng','originalRxAng');
title('Rotation Angles Change [degrees]');

subplot(3,4,7); plot(1:numel(currentResults),newRang(:,2).*180./pi());
hold on; plot(1:numel(currentResults),repelem(origRbeta.*180./pi(),numel(currentResults)),'--');grid minor;
legend('newRyAng','originalRyAng');
title('Rotation Angles Change [degrees]');

subplot(3,4,8); plot(1:numel(currentResults),newRang(:,3).*180./pi());
hold on; plot(1:numel(currentResults),repelem(origRgamma.*180./pi(),numel(currentResults)),'--');grid minor;
legend('newRzAng','originalRzAng');
title('Rotation Angles Change [degrees]');

subplot(3,4,9); plot(1:numel(currentResults),KdepthNew(:,1));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Kdepth(1,1),numel(currentResults)),'--');
legend('newFx','originalFx'); grid minor;
title('K Depth Matrix Change');

subplot(3,4,10); plot(1:numel(currentResults),KdepthNew(:,2));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Kdepth(2,2),numel(currentResults)),'--');
legend('newFy','originalFy'); grid minor;
title('K Depth Matrix Change');

subplot(3,4,11); plot(1:numel(currentResults),KdepthNew(:,3));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Kdepth(1,3),numel(currentResults)),'--');
legend('newPx','originalPx'); grid minor;
title('K Depth Matrix Change');

subplot(3,4,12); plot(1:numel(currentResults),KdepthNew(:,4));
hold on; plot(1:numel(currentResults),repelem(currentResults(1).originalParams.Kdepth(2,3),numel(currentResults)),'--');
legend('newPy','originalPy'); grid minor;
title('K Depth Matrix Change');

figure; 
count = 0;
for ix1 = 1:3
    for ix2 = 1:4
        count = count + 1;
        subplot(3,4,count); plot(1:numel(currentResults),Pnew(:,ix1,ix2)); hold on;
        plot(1:numel(currentResults),PnewFromDepth(:,ix1,ix2));
        legend('newPopt','newPfromKdepthRTopt'); grid minor;
        title(['P' num2str(ix1) ',' num2str(ix2)]);
    end
end


% a = [currentResults.desicionParamsP];
% subplot(3,1,3);plot(1:numel(a),[a.isValid],'^');
% hold on;plot(1:numel(a),[a.isValid_1]);
% a = [currentResults.desicionParamsKrgbRT];
% hold on; plot(1:numel(a),[a.isValid],'--');
% hold on;plot(1:numel(a),[a.isValid_1],'-.');
% a = [currentResults.desicionParamsKdepthRT];
% hold on; plot(1:numel(a),[a.isValid],'s');
% hold on;plot(1:numel(a),[a.isValid_1],'*');
% legend('POptInValidity','POptOutValidity','KRTOptInValidity','KRTOptOutValidity','KdepthRTOptInValidity','KdepthRTOptOutValidity'); grid minor;
% title('Input and Output Optimiztion Validity');

global runParams;
runParams.loadSingleScene = 1;
frame = OnlineCalibration.aux.loadZIRGBFrames(currentResults(1).sceneFullPath);
figure; subplot(3,1,1); imagesc(frame.yuy2(:,:,2)); title('yuy2 Image');impixelinfo;
subplot(3,1,2); imagesc(frame.i); title('IR Image');impixelinfo;
subplot(3,1,3); imagesc(frame.z./4); title('Depth Image');impixelinfo;
