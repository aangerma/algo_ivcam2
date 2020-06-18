function [data] = processSingleLut(fname,metricNames,showFig)
    if ~exist('showFig','var')
        showFig = false;
    end
    data = struct();
    tbl = readtable(fname);
    
    data.hfactors = unique(tbl.hScale);
    data.vfactors = unique(tbl.vScale);
    sz = [length(data.vfactors),length(data.hfactors)];
    if prod(sz) ~= size(tbl,1)
        tbl = tbl(1:prod(sz),:);
    end
    
    hfactor = tbl.hScale;
    vfactor = tbl.vScale;
    
    data.hfactor = reshape(hfactor,sz);
    data.vfactor = reshape(vfactor,sz);
    data.sn = tbl.sn{1};
    data.metrics = [];
    
    fields = fieldnames(tbl);
    if ~exist('metricNames','var') || isempty(metricNames)
        metricNames = {'LDD_Temperature','gridInterDistance_errorRmsAF',...
            'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
            'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
    elseif ischar(metricNames) && strcmp(metricNames,'all')
        metricNames = fields(find(strcmp(fields,'vScale')):end);
    end
    
    for midx=1:length(metricNames)
        curData = tbl.(metricNames{midx});
        if isnumeric(curData)
            data.metrics(midx).name = metricNames{midx};
            data.metrics(midx).values = reshape(curData,sz);
        end
    end
    
    if showFig
        fig = figure();
        
        for midx=1:length(data.metrics)
            tabplot(midx,fig);
            OnlineCalibration.robotAnalysis.dispLut(data.metrics(midx).values,data.hfactors,data.vfactors);
            title(data.metrics(midx).name,'interpreter', 'none');
        end
    end
    
    
end




