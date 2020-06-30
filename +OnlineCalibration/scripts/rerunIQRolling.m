rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\18-06-20\Rolling_v0.9.22\Julia\J315';
outputDir = 'X:\Users\tmund\dbgIQRolling\rerunIQT155';
outputResFile = fullfile(outputDir,'res.mat');
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes,outputDir)


rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\16-06-20\Rolling\Tomer\T174';
outputDir = 'X:\Users\tmund\dbgIQRolling\rerunIQT174';
outputResFile = fullfile(outputDir,'res.mat');
outputDir = [];
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes,outputDir)


rerunDir = '\\syn03.iil.intel.com\VIDB\AC2 Field Test\Data Collection\18-06-20\Rolling_v0.9.20\Dariia\D285';
outputDir = 'X:\Users\tmund\dbgIQRolling\rerunIQD285';
outputResFile = fullfile(outputDir,'res.mat');
outputDir = [];
runMultiFrame = 0;
numberOfScenes = 60;
OnlineCalibration.datasetAnalysis.rerunIQSubFolder(rerunDir,outputResFile,runMultiFrame,numberOfScenes,outputDir)


sefFn = {'rerunIQT155';'rerunIQT174';'rerunIQD285'};
for l = 1:numel(sefFn)
    load(fullfile('X:\Users\tmund\dbgIQRolling',sefFn{l},'res.mat'));
    validity = [res.validParamsRerun];
    hFactorOut = getFields(res,'dbgRerun','acDataOut','hFactor');
    vFactorOut = getFields(res,'dbgRerun','acDataOut','vFactor');
    validity = [1,validity];
    hFactorOut = [res(1).dbgRerun.acDataIn.hFactor,hFactorOut];   
    vFactorOut = [res(1).dbgRerun.acDataIn.vFactor,vFactorOut];   
    hFactorTrue = zeros(1,numel(hFactorOut));
    vFactorTrue = zeros(1,numel(hFactorOut));
    
    hFactorOutNoClip = getFields(res,'dbgRerun','acDataOutPreClipping','hFactor')
    vFactorOutNoClip = getFields(res,'dbgRerun','acDataOutPreClipping','vFactor')
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
load('rerunIQT155.mat')
getFields(res,'newAcData','hFactor')
plot(getFields(res,'newAcData','hFactor'))
hold on
plot(getFields(res,'newAcData','vFactor'))

getFields(res,'dbgRerun','acDataOutPreClipping','hFactor')
plot(getFields(res,'dbgRerun','acDataOutPreClipping','hFactor'))
hold on
plot(getFields(res,'dbgRerun','acDataOutPreClipping','vFactor'))