function [rtdOverXTableFullPath] = RtdOverAngX_Calib_Calc_int(imConstant, imSteps, calibParams, regs, luts, runParams)

diffRTD = single(imSteps-imConstant)*2/4;

delayValues = -single(1:calibParams.rtdOverAngX.res)*calibParams.rtdOverAngX.stepSize;

% Define area sections
d = abs((diffRTD(:) + delayValues));
[~,areaI] = min(d,[],2);
areas = reshape(areaI,size(imSteps));
areasFixed = areas;
for i = 1:calibParams.rtdOverAngX.res % Keep only largest connected component of each type
    CC = bwconncomp(areas==i);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [~,idx] = max(numPixels);
    for k = 1:CC.NumObjects
        if k == idx
            continue;
        end
        areasFixed(CC.PixelIdxList{k}) = 0;
    end
end

[angxQ,angyQ] = meshgrid(linspace(-2047,2047,500),linspace(-2047,2047,500));
[x_,y_] = Pipe.DIGG.ang2xy(angxQ(:),angyQ(:),regs,[],[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,[],[]);
x = single(x)/2^15+0.5; 
y = single(y)/2^15+0.5; 

[Xq,Yq] = meshgrid(1:size(imSteps,2),1:size(imSteps,1));
angXimage = griddata(double(x),double(y),angxQ(:),double(Xq(:)),double(Yq(:)));
groups = areasFixed(:) == 1:calibParams.rtdOverAngX.res;
meanAngXPerGroup = sum(groups.*angXimage)./sum(groups);
% figure,stem(meanAngXPerGroup)
% For each area, convert all pixels to angx,angy and represent by the
% average angx value.
[x_,y_] = Pipe.DIGG.ang2xy(meanAngXPerGroup(:),0*meanAngXPerGroup(:),regs,[],[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,[],[]);
x = single(x)/2^15+0.5; 
y = single(y)/2^15+0.5; 

% The values of the fix:
rtd2add = Calibration.DFZ.applyRtdOverAngXFix( meanAngXPerGroup(:),regs );
tableValues = -rtd2add + regs.DEST.txFRQpd(1);
tableValues = Calibration.tables.fillStartNans(tableValues);   
tableValues = flipud(Calibration.tables.fillStartNans(flipud(tableValues)));  

% table generation
calibData = struct('table', tableValues);
binTable = convertCalibDataToBinTable(calibData, 'Algo_rtdOverAngX_CalibInfo');
rtdOverXTableFileName = Calibration.aux.genTableBinFileName('Algo_rtdOverAngX_CalibInfo', calibParams.tableVersions.algoRtdOverAngX);
rtdOverXTableFullPath = fullfile(runParams.outputFolder,'calibOutputFiles', rtdOverXTableFileName);
writeAllbytes(binTable, rtdOverXTableFullPath);

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    ff = Calibration.aux.invisibleFigure; 
    imagesc(areas);
    hold on,
    plot(x,y,'r*');
    title('RTD Over AngX Fix Slices and sampled locations');
    Calibration.aux.saveFigureAsImage(ff,runParams,'DFZ','RTD_Over_AngX_Slices') 
    
    ff = Calibration.aux.invisibleFigure; 
    imagesc(diffRTD,[0,max(abs(delayValues))]);
    title('RTD Over AngX Fix Slices and sampled locations');
    Calibration.aux.saveFigureAsImage(ff,runParams,'DFZ','Rtd_Step_Diff') 
end
end

