baseDir ='\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\06-07-20\Rolling_v1.0.0\V=H=1';%'\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\09-07-20\Rolling_V(1.1.0)\Benny';
sefFn = [];
dirData = dir(fullfile(baseDir,'*_checker*'));
for k = 1:numel(dirData)
    rerunDir = fullfile(baseDir,dirData(k).name);
    [~,name,~] = fileparts(rerunDir);
    outputDir = fullfile('X:\Users\mkiperwa\onlineCalibration\dbgIQRolling\06-07-20',['rerunIQ' name]);
    sefFn{k} = ['rerunIQ' name];
    mkdirSafe(outputDir);
    outputResFile = fullfile(outputDir,'res.mat');
    runMultiFrame = 0;
    numberOfScenes = 60;
    OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes)
    load(fullfile(outputDir,'res.mat'));
    OnlineCalibration.robotAnalysis.plotRollingValidity(res,fullfile(outputDir,'RollingValidity.png'),0);
end

%{
rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\09-07-20\Rolling_V(1.1.0)\Benny\B1249_checker';
outputDir = 'X:\Users\mkiperwa\onlineCalibration\dbgIQRolling\rerunIQB1249_checker';
mkdirSafe(outputDir);
outputResFile = fullfile(outputDir,'res.mat');
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes)
load(fullfile(outputDir,'res.mat'));
OnlineCalibration.robotAnalysis.plotRollingValidity(res,'RollingValidity.png',1);


rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\09-07-20\Rolling_V(1.1.0)\Benny\B1407_checker';
outputDir = 'X:\Users\mkiperwa\onlineCalibration\dbgIQRolling\rerunIQB1407_checker';
mkdirSafe(outputDir);
outputResFile = fullfile(outputDir,'res.mat');
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes)
load(fullfile(outputDir,'res.mat'));
OnlineCalibration.robotAnalysis.plotRollingValidity(res,'RollingValidity.png',1);


rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\09-07-20\Rolling_V(1.1.0)\Benny\B1421_checker';
outputDir = 'X:\Users\mkiperwa\onlineCalibration\dbgIQRolling\rerunIQB1421_checker';
mkdirSafe(outputDir);
outputResFile = fullfile(outputDir,'res.mat');
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes)
load(fullfile(outputDir,'res.mat'));
OnlineCalibration.robotAnalysis.plotRollingValidity(res,'RollingValidity.png',1);
%}
%%
% sefFn = {'rerunIQB1249_checker';'rerunIQB1407_checker';'rerunIQB1421_checker'};
for l = 1:numel(sefFn)
    load(fullfile('X:\Users\mkiperwa\onlineCalibration\dbgIQRolling\06-07-20',sefFn{l},'res.mat'));
    validity = [res.validParamsRerun];
    hFactorOut = getFields(res,'dbgRerun','acDataOut','hFactor');
    vFactorOut = getFields(res,'dbgRerun','acDataOut','vFactor');
    validity = [1,validity];
    hFactorOut = [res(1).dbgRerun.acDataIn.hFactor,hFactorOut];   
    vFactorOut = [res(1).dbgRerun.acDataIn.vFactor,vFactorOut];   
    hFactorTrue = zeros(1,numel(hFactorOut));
    vFactorTrue = zeros(1,numel(hFactorOut));
    
    hFactorOutNoClip = getFields(res,'dbgRerun','acDataOutPreClipping','hFactor');
    vFactorOutNoClip = getFields(res,'dbgRerun','acDataOutPreClipping','vFactor');
    hFactorOutNoClip = [res(1).dbgRerun.acDataIn.hFactor,hFactorOutNoClip];   
    vFactorOutNoClip = [res(1).dbgRerun.acDataIn.vFactor,vFactorOutNoClip];   
    for k = (1:numel(hFactorTrue))
        if validity(k)
            hFactorTrue(k) = hFactorOut(k);
            vFactorTrue(k) = vFactorOut(k);
        else
            hFactorTrue(k) = hFactorTrue(k-1);
            vFactorTrue(k) = vFactorTrue(k-1);
        end
    end
    figure;
    subplot(121);
    plot(hFactorTrue)
    hold on
    plot(hFactorOutNoClip)
    grid minor
    title(sprintf('%s - hFactors',sefFn{l}))
    legend({'clipped';'No Clip'});
    
    subplot(122);
    plot(vFactorTrue)
    hold on
    plot(vFactorOutNoClip)
    grid minor
    title(sprintf('%s - vFactors',sefFn{l}))
    legend({'clipped';'No Clip'});
end
% load(fullfile(outputDir,'res.mat'));
% 
% getFields(res,'newAcData','hFactor')
% plot(getFields(res,'newAcData','hFactor'))
% hold on
% plot(getFields(res,'newAcData','vFactor'))
% 
% getFields(res,'dbgRerun','acDataOutPreClipping','hFactor')
% plot(getFields(res,'dbgRerun','acDataOutPreClipping','hFactor'))
% hold on
% plot(getFields(res,'dbgRerun','acDataOutPreClipping','vFactor'))

