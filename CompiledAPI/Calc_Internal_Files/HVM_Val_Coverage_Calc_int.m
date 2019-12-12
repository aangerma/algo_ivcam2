function [valResults ,allCovRes] = HVM_Val_Coverage_Calc_int(frameBytes,sz,runParams,calibParams,fprintff,valResults)
    width = sz(2);
    height = sz(1);
    defaultDebug = 0;
    outFolder = fullfile(runParams.outputFolder,'Validation',[]);
    mkdirSafe(outFolder);
    debugMode = flip(dec2bin(uint16(defaultDebug),2)=='1');

%% load images
    im = Calibration.aux.convertBytesToFrames(frameBytes, sz, [], false);
    for i =1:1:size(im.i,3)
        frames(i).i = im.i(:,:,i);
    end
  
    Metrics = 'coverage';
%    covConfig = calibParams.validationConfig.(Metrics);
    %calculate ir coverage metric
    [covScore,allCovRes, dbg] = Validation.metrics.irFillRate(frames);
    dbg.probIm;
    covRes.irCoverage = covScore;
    fprintff('ir Coverage:  %2.2g\n',covScore);
    valResults = Validation.aux.mergeResultStruct(valResults, covRes);
    saveValidationData(dbg,frames,Metrics,outFolder,debugMode);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function saveValidationData(debugData,frames,metric,outFolder,debugMode)
    
    % debug mode 1 indicates if we store the debug data of the metric
    if debugMode(1) && ~isempty(debugData)
        save(fullfile(outFolder,[metric '.mat']),'debugData');
    end
    
    % debug mode 2 indicates if we store the frames data of the metric
    if debugMode(2) && ~isempty(frames)
        f = fieldnames(frames);
        for i = 1:length(f)
            imfn = fullfile(dirname,strcat(metric,'Frame_',f{i},'.png'));
            imwrite(frames.(f{i}),imfn);
        end
    end
    
end