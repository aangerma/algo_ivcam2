clear;
baseDir ='X:\Users\mkiperwa\onlineCalibration\AvishaiDebug\Repetitive Pattern Diverge';
collector = strsplit(baseDir,'\');
collector = collector{end};
name = [];
dirData = dir(fullfile(baseDir,'Scene*'));
for k = 1:numel(dirData)
    rerunDir = fullfile(baseDir,dirData(k).name);
    [~,name{k},~] = fileparts(rerunDir);
    outputDir = fullfile(rerunDir,'rerun');
    mkdirSafe(outputDir);
    outputResFile = fullfile(outputDir,'res.mat');
    runMultiFrame = 0;
    OnlineCalibration.datasetAnalysis.rerunAc2_1DataCollectionSubFolder(rerunDir,outputResFile,runMultiFrame)
    load(fullfile(outputDir,'res.mat'));
    OnlineCalibration.robotAnalysis.plotRollingValidity(res,fullfile(outputDir,'RollingValidity.png'),0);
end

%%
for l = 1:numel(name)
    load(fullfile(baseDir,name{l},'rerun','res.mat'));
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
    
    ff = Calibration.aux.invisibleFigure;
    subplot(121);
    plot(hFactorTrue)
    hold on
    plot(hFactorOutNoClip)
    grid minor
    title(sprintf('%s - hFactors',[collector ' ' name{l}]))
    legend({'clipped';'No Clip'});
    
    subplot(122);
    plot(vFactorTrue)
    hold on
    plot(vFactorOutNoClip)
    grid minor
    title(sprintf('%s - vFactors',[collector ' ' name{l}]))
    legend({'clipped';'No Clip'});
    set(0, 'currentfigure', ff);
    saveas(ff,fullfile(baseDir,name{l},'rerun','h_vFactors.png'));
    close(ff);
end
