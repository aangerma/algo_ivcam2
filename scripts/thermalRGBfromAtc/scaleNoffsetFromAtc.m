hengPath = 'S:\IVCAM\L515\Calibration\BIG PBS\HENG-2857';
atcPath = {'F9340423-gradual\ATC gradual 5-60 - 215','F9340423-gradual-3.15.0.0\ATC18','15-12\F9340026\ATC13','15-12\F9340068\ATC21','15-12\F9340568\ATC12','15-12\F9340876\ATC3','15-12\F9340254\ATC4',...
    '17-12\F9340361\ATC2'};
for k = 1:numel(atcPath)
    folderPath = '\Matlab\mat_files';
    strSplitted = strsplit(atcPath{k},'\');
    unitData = strSplitted{end-1};
    load(fullfile(hengPath,atcPath{k},folderPath,'finalCalcAfterHeating_in.mat'));
    nBinsRgb = calibParams.fwTable.nRowsRGB;
    ptsWithZ = reshape([data.framesData.ptsWithZ],560,7,[]);
    rgbCrnrsPerFrame = ptsWithZ(:,6:7,:);
    tempData = [data.framesData.temp];
    ldd = [tempData.ldd];

    minMaxLdd4RGB = minmax(ldd);
    lddGridEdges = linspace(minMaxLdd4RGB(1),minMaxLdd4RGB(2),nBinsRgb+2);
    lddStepRgb = lddGridEdges(2)-lddGridEdges(1);
    lddGridRgb = lddStepRgb/2 + lddGridEdges(1:end-1);
    rgbGrid = NaN(size(rgbCrnrsPerFrame,1),size(rgbCrnrsPerFrame,2),nBinsRgb+1);
    for ixLdd = 1:length(lddGridRgb)
        idcs = abs(ldd - lddGridRgb(ixLdd)) <= lddStepRgb/2;
        if ~sum(idcs)
            continue;
        end
        rgbGrid(:,:,ixLdd) = nanmedian(rgbCrnrsPerFrame(:,:,idcs),3);
    end
    refPts = rgbGrid(:,:,end);
    B1 = refPts(:,1);
    B2 = refPts(:,2);
    scaleX = nan(nBinsRgb,1);
    scaleY = nan(nBinsRgb,1);
    transX = nan(nBinsRgb,1);
    transY = nan(nBinsRgb,1);
    for ixBin = 1:nBinsRgb
        ptsCurr = rgbGrid(:,:,ixBin);
        A = [ptsCurr(:,1) ones(size(ptsCurr,1),1)];
        mask = ~isnan(B1) &~isnan(A(:,1));
        x1=A(mask,:)\B1(mask);
        scaleX(ixBin,1) = x1(1);
        transX(ixBin,1) = x1(2);
        
        A = [ptsCurr(:,2) ones(size(ptsCurr,1),1)];
        x2=A(mask,:)\B2(mask);
        scaleY(ixBin,1) = x2(1);
        transY(ixBin,1) = x2(2);
    end
    figure(151285);
    if k ~= 2
        tabplot;
    end
    temps = lddGridRgb(1:end-1);
    subplot(221); plot(temps,scaleX); title({unitData;'Scale X'}); hold on; grid minor;
    subplot(222); plot(temps,scaleY); title({unitData;'Scale Y'}); hold on; grid minor;
    subplot(223); plot(temps,transX); title({unitData;'Translation X'}); hold on; grid minor;
    subplot(224); plot(temps,transY); title({unitData;'Translation Y'}); hold on; grid minor;
    load(fullfile(hengPath,atcPath{k},folderPath,'finalCalcAfterHeating_out.mat'));
    
    figure(151283);
    if k ~= 2
        tabplot;
    end
    thermalTable = data.tableResults.rgb.thermalTable;
    subplot(221); plot(temps,thermalTable(:,1)); title({unitData;'Scale*cosine(angle)'}); grid minor; hold on;
    subplot(222); plot(temps,thermalTable(:,2)); title({unitData;'Scale*sine(angle)'}); grid minor; hold on;
    subplot(223); plot(temps,thermalTable(:,3)); title({unitData;'Translation X'}); grid minor; hold on;
    subplot(224); plot(temps,thermalTable(:,4)); hold on; title({unitData;'Translation Y'}); grid minor;
    %{%}
end