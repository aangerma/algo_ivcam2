clear
close all

testSubName = '_crawling';
resultsHeadDir = 'X:\IVCAM2_calibration _testing\crawlingResults';
dataPath = '\\143.185.124.231\ivcam_lidar\testResults\05201048\**\';
datafiles = dir(fullfile(dataPath,'*_data.mat'));
nSeries = 150;
for kkk = 1:10
    datafiles = datafiles(randperm(numel(datafiles)));
    
    testParams.useLastRTKrgb = 1;
    iterFromStart = 1;
    for i = 1:nSeries
        data = load(fullfile(datafiles(i).folder,datafiles(i).name));
        params = data.params;
        
        frame = data.frame;
        dataForACTableGeneration = data.dbg.dataForACTableGeneration;
        params.svmModelPath = fullfile(ivcam2root,'+OnlineCalibration','+SVMModel','SVMModelLinear.mat');
        params.iterFromStart = iterFromStart;
        if i > 1
            if validParamsRerun
                params.acData = newAcData;
                if testParams.useLastRTKrgb
                    params.Rrgb = paramsRerun.Rrgb;
                    params.Trgb = paramsRerun.Trgb;
                    params.rgbPmat = paramsRerun.rgbPmat;
                    params.Krgb = paramsRerun.Krgb;
                end
            else
                params.acData = results(end).dbgRerun.acDataIn;
            end
        else
            originalParams = data.originalParams;
        end
        params.maxLosScalingStep = 0.02;
        params.maxGlobalLosScalingStep = 0.002;
        [validParamsRerun,paramsRerun,newAcDataTableRerun,newAcData,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams,dataForACTableGeneration);
        sceneResults.valid = validParamsRerun;
        sceneResults.hFactorOut = newAcData.hFactor;
        sceneResults.vFactorOut = newAcData.vFactor;
        sceneResults.dbgRerun = dbgRerun;
        sceneResults.decisionParams = dbgRerun.decisionParams;
        sceneResults.finalParams = dbgRerun.finalParams;
        if validParamsRerun
            sceneResults.hFactor = newAcData.hFactor;
            sceneResults.vFactor = newAcData.vFactor;
        else
            sceneResults.hFactor = dbgRerun.acDataIn.hFactor;
            sceneResults.vFactor = dbgRerun.acDataIn.vFactor;
        end
        results(i) = sceneResults;
        fprintf('[%d] %d, %4.4g, %4.4g\n',i, sceneResults.valid, newAcData.hFactor, newAcData.vFactor);
        if validParamsRerun
            iterFromStart = iterFromStart + 1;
        end
    end
    
    
    str = strsplit(dataPath,'\'); str = str{end};
    outputDir = fullfile(resultsHeadDir,str);
    mkdirSafe(outputDir);
    save(fullfile(outputDir,sprintf('results_150_%03d.mat',kkk)),'results');
    clear results
end