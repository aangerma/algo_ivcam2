function dfzRefTmp = recalcRefTempForBetterEGeom(data,calibParams,runParams,fprintff)
% Find ~minimal eGeom value
invalidFrames = arrayfun(@(j) isempty(data.framesData(j).ptsWithZ),1:numel(data.framesData));
data.framesData = data.framesData(~invalidFrames);
nFilters = 2;
C = 5;
M = floor(C/2) * nFilters;
filt = 1/C*ones(1,C);
eg = filter(filt,1,[data.framesData.eGeom]);
eg = filter(filt,1,eg);

lddTemp = [data.framesData.temp];
lddTemp = [lddTemp.ldd];

candEg = eg;
candEg(1:round(max(M,numel(eg)/10))) = nan;
[~,minI] = min(candEg);
% Ignore first 10% of frames
if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure;
    plot(lddTemp,[data.framesData.eGeom]);
    hold on
    plot(lddTemp,eg)
    hold on
    plot(lddTemp,candEg),hold on
    % remove outliers
    refMark = plot(lddTemp(minI),candEg(minI),'o','LineWidth',2,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor',[.49 1 .63],...
        'MarkerSize',10);
    hold on

    calI = find(lddTemp>data.regs.FRMW.dfzCalTmp,1);

    calMark = plot(lddTemp(calI),candEg(calI),'o','LineWidth',2,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor',[.49 .63 1],...
        'MarkerSize',10);
    grid on
    legend([refMark calMark],{'chosenRef','calLddPoint'});
    title(sprintf('eGeom over temp. eGeom(calLdd) = %1.2f, eGeom(chosenLddRef) = %1.2f',candEg(calI),candEg(minI)));

    Calibration.aux.saveFigureAsImage(ff,runParams,'Results',sprintf('newRefLdd'),1);
end


dfzRefTmp = lddTemp(minI);
fprintff('Chosen ldd ref: %2.2f. EGeom at chosen temp: %2.2f\n',dfzRefTmp,candEg(minI));

end

