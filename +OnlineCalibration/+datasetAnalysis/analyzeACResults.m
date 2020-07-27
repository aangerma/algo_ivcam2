function analyzeACResults(resMat,varargin)
% This function recieves a path to a result file name
% The file contains a struct array with information across many runs of AC
% Other inputs are name/value pairs
p = inputParser;
addRequired(p,'resMat');
addParameter(p,'metricsSavePath','',@isstr);
% addOptional(p,'markovOnlyValid',0,@isnumeric);
% addOptional(p,'saveFigures',0,@isnumeric);
addParameter(p,'pathFilterStr','');
addParameter(p,'dbAnalysisFlags',struct);
% addParameter(p,'units','mm',@isstring);
parse(p,resMat,varargin{:});
funcParams = p.Results;
dbAnalysisFlags = funcParams.dbAnalysisFlags;
%% Calculate Before/After For all metrics
metricLutNames = {'gridInterDistance_errorRmsAF',...
    'gridDistortion_horzErrorMeanAF','gridDistortion_vertErrorMeanAF',...
    'geomReprojectErrorUV_rmseAF','geomReprojectErrorUV_maxErrAF'};
friendlyNames = {'GID','ScaleX','ScaleY','LUT UV RMS','LUT UV max','UV RMS','UV max'};
extraDataNames = {'H Factor', 'V Factor'};
kpi = [1.2+eps, 0.005+eps, 0.005+eps, 4+eps, 8+eps, 4+eps, 8+eps];
binCenters = {0.8:0.4:3.2;...
              -0.01:0.001:0.01;...
              -0.01:0.001:0.01;...
              2:1:10;...
              2:1:10;...
              2:1:10;...
              2:1:10};
mUnits = {'mm','factor','factor','pix','pix','pix','pix'};
      
% If in multi frame mode, and we are always valid, apply the results in
% retrospect to all scenes in the list
if isfield(dbAnalysisFlags,'multiFrameFlow') && dbAnalysisFlags.multiFrameFlow
    for i = flip(1:numel(resMat)-1)
       if ~resMat(i).IsConverge && strcmp(resMat(i).unitID,resMat(i+1).unitID)
           resMat(i).IsConverge = resMat(i+1).IsConverge;
           if resMat(i).IsConverge
               outputState = resMat(i+1).outputState;
               outputStateNoClipping = resMat(i+1).outputStateNoClipping;
               outputState.Krgb = du.math.getK(du.math.normalizeK(outputState.Krgb, single(outputState.rgbRes)), single(resMat(i).outputState.rgbRes)); 
               outputStateNoClipping.Krgb = outputState.Krgb;
               outputState.rgbRes = resMat(i).outputState.rgbRes;
               outputStateNoClipping.rgbRes = resMat(i).outputState.rgbRes;
               resMat(i).outputState = outputState;
               resMat(i).outputStateNoClipping = outputStateNoClipping;
           end
       end
    end
end

% In itialize metrics struct array
for m = 1:numel(friendlyNames)
    metrics(m).name = friendlyNames{m};
    metrics(m).unit = mUnits{m};
    metrics(m).pre = nan(1,numel(resMat));
    metrics(m).post = nan(1,numel(resMat));
    metrics(m).postNoClipping = nan(1,numel(resMat));
    metrics(m).kpi = kpi(m);
    metrics(m).markovBinCenters = binCenters{m};
    metrics(m).gtFunc = @(be,af) abs(be) > abs(af) | af < kpi(m);
end
        
for i = 1:numel(resMat)
    fprintf('Processing scene %d/%d\n',i,numel(resMat));
    res = resMat(i);
    if ~isempty(funcParams.pathFilterStr) &&  (contains(res.framePath,funcParams.pathFilterStr) || contains(res.unitID,funcParams.pathFilterStr))
        continue; 
    end
    if isfield(dbAnalysisFlags,'dataBase') && strcmp(dbAnalysisFlags.dataBase{1},'robot')
        res.lutPath = fullfile(fileparts(res.lutPath),'init_lutTable.csv');
    end
    lutData = OnlineCalibration.aux.fetchLutFromDict(res.lutPath,metricLutNames);
    if numel(metricLutNames) ~= numel(lutData.metrics)
        metrics(numel(lutData.metrics)+1:numel(metricLutNames)) = [];
        metricLutNames = {lutData.metrics.name};
        
    end
    % Metrics from Luts
    for m = 1:numel(metricLutNames)
        metrics(m).pre(i) = interp2(lutData.hfactor,lutData.vfactor,lutData.metrics(m).values,res.inputState.hfactor,res.inputState.vfactor);
        metrics(m).post(i) = interp2(lutData.hfactor,lutData.vfactor,lutData.metrics(m).values,double(res.outputState.hfactor),double(res.outputState.vfactor));
        metrics(m).postNoClipping(i) = interp2(lutData.hfactor,lutData.vfactor,lutData.metrics(m).values,res.outputStateNoClipping.hfactor,res.outputStateNoClipping.vfactor);
    end

    uvPre = num2cell(OnlineCalibration.robotAnalysis.calcUvMapError(...
        lutData.lutCheckers,res.inputState.hfactor,res.inputState.vfactor,res.inputState));
    uvPost = num2cell(OnlineCalibration.robotAnalysis.calcUvMapError(...
        lutData.lutCheckers,res.outputState.hfactor,res.outputState.vfactor,res.outputState));
    uvPostNoClipping = num2cell(OnlineCalibration.robotAnalysis.calcUvMapError(...
        lutData.lutCheckers,res.outputStateNoClipping.hfactor,res.outputStateNoClipping.vfactor,res.outputState));
    [metrics(numel(metricLutNames)+1).pre(i),metrics(numel(metricLutNames)+2).pre(i)] = uvPre{1:2};
    [metrics(numel(metricLutNames)+1).post(i),metrics(numel(metricLutNames)+2).post(i)] = uvPost{1:2};
    [metrics(numel(metricLutNames)+1).postNoClipping(i),metrics(numel(metricLutNames)+2).postNoClipping(i)] = uvPostNoClipping{1:2};
%     
%     metrics(numel(metricLutNames)+3).pre(i) = res.inputState.hfactor;
%     metrics(numel(metricLutNames)+4).pre(i) = res.inputState.vfactor;
%     metrics(numel(metricLutNames)+3).post(i) = res.outputState.hfactor;
%     metrics(numel(metricLutNames)+4).post(i) = res.outputState.vfactor;
%     metrics(numel(metricLutNames)+3).postNoClipping(i) = res.outputStateNoClipping.hfactor;
%     metrics(numel(metricLutNames)+4).postNoClipping(i) = res.outputStateNoClipping.vfactor;
end

if ~isempty(funcParams.metricsSavePath)
    save(funcParams.metricsSavePath,'metrics');
end



validPoints = logical([resMat.IsConverge]);
for i = 1:numel(metrics)
    % For each metric plot:
    
    % Before after histograms with clipping   (figure 3.1)
%     figure(1);
%     subplot(3,3,i);
%     histogram(metrics(i).pre(validPoints),10);
%     hold on
%     histogram(metrics(i).post(validPoints),10);
%     legend({'Pre';'Post'});
%     title(sprintf('%s',metrics(i).name));
%     xlabel(sprintf('%s[%s]',metrics(i).name,metrics(i).unit));
%     % Before after histogrms without clipping (figure 3.2)
%     figure(2);
%     subplot(3,3,i);
%     histogram(metrics(i).pre(validPoints),10);
%     hold on
%     histogram(metrics(i).postNoClipping(validPoints),10);
%     legend({'Pre';'Post'});
%     title(sprintf('%s No Clipping',metrics(i).name));
%     xlabel(sprintf('%s[%s]',metrics(i).name,metrics(i).unit));
%     % Sleeve plot after clipping (figure 4.1)
%     figure(3);
%     subplot(3,3,i);
%     OnlineCalibration.aux.metricSleevePlot(metrics(i),validPoints,1);
%     % Sleeve plot without clipping (figure 4.2)
%     figure(4);
%     subplot(3,3,i);
%     OnlineCalibration.aux.metricSleevePlot(metrics(i),validPoints,0);
%     
    % Confusion matrix by improvement (figure 5)
    figure(5);
    subplot(3,3,i);
    gtLabel = metrics(i).gtFunc(metrics(i).pre,metrics(i).post);
    nanLabels = isnan(metrics(i).pre) | isnan(metrics(i).post);
    cm = confusionchart(gtLabel(~nanLabels),validPoints(~nanLabels));
    xlabel('Valid Optimization');
    ylabel(sprintf('Improved %s Err',metrics(i).name));
    title(sprintf('acc = %2.0f',100*nanmean(gtLabel(~nanLabels)==validPoints(~nanLabels))));
    
    % Markov - Markov chain steady state (figure 1.1)
    [Q,probSS,timeToHitKpi] = OnlineCalibration.aux.metricsToMarkovChain(metrics(i),validPoints);
    figure(6);
    subplot(3,3,i);
    plot(metrics(i).markovBinCenters,probSS')
    hold on;
    plot([metrics(i).kpi,metrics(i).kpi],[0,max(probSS(:))],'r');
    ylim([0,1])
    title(sprintf('Steady State PDF - %2.0f%% Under KPI',100*sum(probSS(metrics(i).markovBinCenters<=metrics(i).kpi))));
    xlabel(sprintf('%s[%s]',metrics(i).name,metrics(i).unit));
    ylabel('Probability');
    grid minor;
    % Markov - If kpi is defined, average time to hit kpi (figure 1.2)
    figure(7),
    subplot(3,3,i);
    plot(metrics(i).markovBinCenters,timeToHitKpi)
    hold on;
    plot([metrics(i).kpi,metrics(i).kpi],[0,max(timeToHitKpi)],'r');
    title(sprintf('Time to hit KPI'));
    xlabel(sprintf('%s[%s]',metrics(i).name,metrics(i).unit));
    ylabel('Steps');
    grid minor;
    % Markov - Visualization of the chain (figure 2)
    figure(8);
    subplot(3,3,i);
    mc = dtmc(Q');
    afterDot = 10;
    StateNames = string(num2str(round(metrics(i).markovBinCenters'*afterDot)/afterDot))';
    mc.StateNames = StateNames;
    y = (-1).^[1:numel(metrics(i).markovBinCenters)];
    G = digraph(mc.P);
    LWidths = 5*G.Edges.Weight/max(G.Edges.Weight);
    EColors = -((G.Edges.EndNodes(:,2) >  G.Edges.EndNodes(:,1)) );
    plot(G,'XData',metrics(i).markovBinCenters,'YData',y,'EdgeLabel',round(G.Edges.Weight*100)/100,'EdgeCData',EColors,'NodeLabel',StateNames,'MarkerSize',7,'LineWidth',LWidths,'NodeColor','r')
    colormap winter
end

end