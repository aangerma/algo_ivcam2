clear all;
close all;
folderPath = 'X:\IVCAM2_calibration _testing\RobotTests';
testNum = 1;
createReportsNcmpr = false;
dataPath = fullfile(folderPath,['test' num2str(testNum)],'data');
dirData = dir(dataPath);
mkdirSafe(fullfile(folderPath,'report'));
counter = 0;
for k = 1:numel(dirData)
    disp(['Running iteration # ' num2str(k) '/' num2str(numel(dirData))]);
    if dirData(k).isdir
        counter = counter + 1;
        continue;
    end
    load(fullfile(dataPath,dirData(k).name));
    hScaleSim(k-counter) = dbg.newAcDataStruct.hFactor;
    vScaleSim(k-counter) = dbg.newAcDataStruct.vFactor;
    
    strSplitted = strsplit(params.svmModelPath, '\');
    params.svmModelPath = fullfile(strSplitted{end-2}, strSplitted{end-1},strSplitted{end});
    dataForACTableGeneration = dbg.dataForACTableGeneration;
    [validParamsRerun,newParamsRerun,~,~,dbgRerun] = OnlineCalibration.aux.runSingleACIteration(frame,params,originalParams,dataForACTableGeneration);
    hScaleRerun(k-counter) = dbgRerun.acDataOut.hFactor;
    vScaleRerun(k-counter) = dbgRerun.acDataOut.vFactor;
    if createReportsNcmpr
        dbg = rmfield(dbg,'dataForACTableGeneration');
        dataName = strsplit(dirData(k).name,'.');
        dataName = dataName{1};
        reportPath = fullfile(folderPath,['test' num2str(testNum)],'report',dataName);
        [isEqualParams] = OnlineCalibration.datasetAnalysis.compareStructs2Level(newParamsRerun,newParams,[reportPath '_newParams_cmpr.txt']);
        [isEqualDbg] = OnlineCalibration.datasetAnalysis.compareStructs2Level(dbgRerun,dbg,[reportPath '_dbg_cmpr.txt']);
        if ~isEqualParams || ~isEqualDbg
            fprintf('Re-run isn''t equal: in %s dbg equality %d, newParams equality %d\n',dataName, isEqualDbg, isEqualParams);
        end
    end
end
lutNresultsPath = fullfile(folderPath,['test' num2str(testNum)],'lutNresults');
lutTable = readtable(fullfile(lutNresultsPath,'lutTable.csv'));
if testNum == 1
    devFactor = [max(lutTable.hScale) max(lutTable.vScale)];
else
    devFactor = [1 1];
end
[minGid,iMinGid] = min(lutTable.gridInterDistance_errorMeanAF);
bestHscale = lutTable.hScale(iMinGid);
bestVscale = lutTable.vScale(iMinGid);

figure; plot(1:numel(hScaleSim),(bestHscale-hScaleSim*devFactor(1))); 
hold on; plot(1:numel(hScaleSim),(bestHscale-hScaleRerun*devFactor(1))); title('Best H scale - AC test H scale'); legend('Original run', 'Re-run'); grid minor;
figure; plot(1:numel(vScaleSim),(bestVscale-vScaleSim*devFactor(2)));
hold on; plot(1:numel(vScaleSim),(bestVscale-vScaleRerun*devFactor(2))); title('Best V scale - AC test V scale'); legend('Original run', 'Re-run'); grid minor;


