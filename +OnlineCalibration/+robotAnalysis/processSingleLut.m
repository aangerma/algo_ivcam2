function [data] = processSingleLut(fname,metricNames,showFig)
    if ~exist('showFig','var')
        showFig = false;
    end
    data = struct();
    [num,txt] = xlsread(fname);
    xDsmErrorIdx = find( strcmp(txt(1,:),'hScale'));
    yDsmErrorIdx = find( strcmp(txt(1,:),'vScale'));
    snIdx = find( strcmp(txt(1,:),'sn'));
    
    data.hfactors = unique(num(:,xDsmErrorIdx));
    data.vfactors = unique(num(:,yDsmErrorIdx));
    sz = [length(data.vfactors),length(data.hfactors)];
    if prod(sz) ~= size(num,1)
        num = num(1:prod(sz),:);
    end
    
    hfactor = num(:,xDsmErrorIdx);
    vfactor = num(:,yDsmErrorIdx);
    
    data.hfactor = reshape(hfactor,sz);
    data.vfactor = reshape(vfactor,sz);
    data.sn = txt(2,snIdx);
    data.metrics = [];
    
    if ~exist('metricNames','var') || isempty(metricNames)
        metricNames = txt(1,max([snIdx,yDsmErrorIdx,xDsmErrorIdx]):end);
    end
    
    for midx=1:length(metricNames)
        idx = find( strcmp(txt(1,:),metricNames{midx}),1,'first');
        if ~isempty(idx) &&  idx <size(num,2)
            data.metrics(midx).name = metricNames{midx};
            data.metrics(midx).values = reshape(num(:,idx),sz);
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




