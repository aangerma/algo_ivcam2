function [isConverged, curScore, nextLaserPoint, minRangeScaleModRef, ModRefDec] = Preset_Short_Calib_Calc_int(Frames, LaserPoints, maxMod_dec, sz, calibParams, output_dir, PresetFolder, testedPoints, testedScores)

runParams.outputFolder = output_dir; % need update
[whiteCenter,blackCenter,ROI_Coffset]=detectROI(Frames(1).i,runParams); % Detecting ROI on low laser image

% analyzing white and black patch
IR=Frames.i;
wpatch=IR(round(whiteCenter(2)-ROI_Coffset(2)):round(whiteCenter(2)+ROI_Coffset(2)),round(whiteCenter(1)-ROI_Coffset(1)):round(whiteCenter(1)+ROI_Coffset(1)));
bpatch=IR(round(blackCenter(2)-ROI_Coffset(2)):round(blackCenter(2)+ROI_Coffset(2)),round(blackCenter(1)-ROI_Coffset(1)):round(blackCenter(1)+ROI_Coffset(1)));
%     figure(); imagesc(IR); hold all;
%     rectangle('position', [round(whiteCenter(1)-ROI_Coffset(1)),round(whiteCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
%     rectangle('position', [round(blackCenter(1)-ROI_Coffset(1)),round(blackCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
[Wmax,Wmean,~]= getIRvalues(wpatch);
[~,~,Bmin]= getIRvalues(bpatch);
testedScores(:,end) = [Wmax; Wmean; double(Wmax-Bmin)];
curScore = testedScores(:,end);

% convergence check
[isConverged, nextLaserPoint] = chooseNextLaserPoint(LaserPoints, testedPoints, testedScores(3,:));
if (isConverged==0) % wait for next iteration
    minRangeScaleModRef = NaN;
    ModRefDec = NaN;
    return
end
p = polyfit(testedPoints, testedScores(3,:), 2);
maxPt = -p(2)/(2*p(1));
if (maxPt < min(LaserPoints))
    isConverged = -1;
    nextLaserPoint = -Inf;
    fprintff('[!] Short range preset calibration: maximal contrast is always exceeded. Modulation ref set to 0.\n')
    minRangeScaleModRef = 0;
    ModRefDec = min(LaserPoints);
    return
elseif (maxPt > max(LaserPoints))
    isConverged = -1;
    nextLaserPoint = Inf;
    fprintff('[!] Short range preset calibration: maximal contrast could not be attained. Modulation ref set to 1.\n')
    minRangeScaleModRef = 1;
    ModRefDec = max(LaserPoints);
    return
end

%% convergence achieved - proceed to final operations

LaserDelta = LaserPoints(2)-LaserPoints(1);
lp=[LaserPoints,LaserPoints(end)+LaserDelta:LaserDelta:2*LaserPoints(end)];
fittedline=p(1)*lp.^2+p(2)*lp+p(3);

if (maxPt > maxMod_dec)
    ModRefDec=maxMod_dec;
else
    ModRefDec = round(maxPt);
end
minRangeScaleModRef = ModRefDec/maxMod_dec*calibParams.presets.short.resultScaleFactor + calibParams.presets.short.resultOffsetFactor;

%% prepare output script
shortRangePresetFn = fullfile(PresetFolder,'shortRangePreset.csv');
shortRangePreset=readtable(shortRangePresetFn);
modRefInd=find(strcmp(shortRangePreset.name,'modulation_ref_factor')); 
if (p(1)> 0)
    warning('MinRange preset calibration failed: first parabola coefficient is possitive\n');
    warning('min modRef already saturated'); 
    minRangeScaleModRef = 0;
    ModRefDec = 0;
end 
%assert(p(1)<0 ,'MinRange preset calibration failed: first parabola coefficient is possitive');     
shortRangePreset.value(modRefInd) = minRangeScaleModRef;
writetable(shortRangePreset,shortRangePresetFn);
%% debug    
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(1,3,1);
    plot(testedPoints,testedScores(1,:),testedPoints,testedScores(2,:)); title('IR values- white patch');xlabel('laser modulation [dec]'); legend('max', 'mean');grid minor;
    subplot(1,3,2);hold all;
    plot(lp,fittedline);plot(testedPoints, testedScores(3,:)); title('DR: Wmax-Bmin');xlabel('laser modulation [dec]');grid minor
    subplot(1,3,3);
    plot(testedPoints,double(testedScores(1,:))-testedScores(2,:)); title(' Wmax-Wmean white patch');xlabel('laser modulation [dec]');grid minor;
    subplot(1,3,2);scatter(ModRefDec,p(1)*ModRefDec.^2+p(2)*ModRefDec+p(3));
    Calibration.aux.saveFigureAsImage(ff,runParams,'SRpresetLaserCalib','PresetDir');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [whiteCenter,blackCenter,ROI_Coffset]=detectROI(im,runParams)
% detect corners and centers
[pts,gridsize] = Validation.aux.findCheckerboard(im,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
ff = Calibration.aux.invisibleFigure;
imagesc(im); hold on;

x=pts(:,1); y=pts(:,2);X=reshape(x,gridsize); Y=reshape(y,gridsize);
patchNum=(gridsize(1)-1)*(gridsize(2)-1);

xcenter=(X(1:end-1,1:end-1)+X(1:end-1,2:end))./2;xcenter=xcenter(:);
ycenter=(Y(1:end-1,1:end-1)+Y(2:end,1:end-1))./2;ycenter=ycenter(:);
recsize=[mean(diff(mean(X,1))),mean(diff(mean(Y,2)))];

scatter(xcenter(:),ycenter(:),'+','MarkerEdgeColor','r','LineWidth',1.5);
%% extract white and black ROI
th=0.8; % ROI size
ROI_Coffset=th*recsize./2;
for j=1:patchNum
    patch=im(round(ycenter(j)-ROI_Coffset(2)):round(ycenter(j)+ROI_Coffset(2)),round(xcenter(j)-ROI_Coffset(1)):round(xcenter(j)+ROI_Coffset(1)));
    meanPatch(j)=mean(patch(:));
    rectangle('position', [round(xcenter(j)-ROI_Coffset(1)),round(ycenter(j)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
end
[~,whitePatchix]=max(meanPatch);
whiteCenter=[xcenter(whitePatchix),ycenter(whitePatchix)];
[p, l]=ind2sub([gridsize(1)-1,gridsize(2)-1],whitePatchix);
blackPatchix=sub2ind([gridsize(1)-1,gridsize(2)-1],p,l-1);
blackCenter=[xcenter(blackPatchix),ycenter(blackPatchix)];
scatter(whiteCenter(1),whiteCenter(2),'+','MarkerEdgeColor','w','LineWidth',1.5);
scatter(blackCenter(1),blackCenter(2),'+','MarkerEdgeColor','k','LineWidth',1.5);

Calibration.aux.saveFigureAsImage(ff,runParams,'ROIforSRpresetLaerCalib','PresetDir');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [max,mean,min]= getIRvalues(im)
im=im(:);
mean = nanmean(im);
max=prctile(im,98);
min=prctile(im,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [isConverged, nextLaserPoint] = chooseNextLaserPoint(laserPoints, testedPoints, testedScores)
% initialization
isConverged = 0;
nextLaserPoint = NaN;
% trivial stop condition
availablePoints = setdiff(laserPoints, testedPoints);
if isempty(availablePoints)
    isConverged = 1;
    return
end
% choosing next point
if (length(testedPoints)==1) % choose another point on search region boundary
    if (testedPoints < max(laserPoints))
        nextLaserPoint = max(laserPoints); % maximal point must be tested once
    else
        nextLaserPoint = min(laserPoints);
    end
elseif (length(testedPoints)==2) % choose an intermediate point
    if (min(testedPoints) > min(laserPoints))
        nextLaserPoint = min(laserPoints); % minimal point must be tested once
    else
        ind = max(1,round(length(laserPoints)/2));
        nextLaserPoint = laserPoints(ind);
    end
else % 3 tested points or more
    p = polyfit(testedPoints, testedScores, 2);
    if (p(1)>=0) % maximum cannot be calculated
        [~,ind] = min(abs(availablePoints-mean(testedPoints(end-1:end)))); % try halving previous step
        nextLaserPoint = availablePoints(ind);
    else
        maxPt = -p(2)/(2*p(1));
        [~,sortIdcs] = sort(abs(laserPoints-maxPt));
        if all(arrayfun(@(x) any(x==testedPoints), laserPoints(sortIdcs(1:3))))
            isConverged = 1;
        else
            [~,ind] = min(abs(availablePoints-maxPt));
            nextLaserPoint = availablePoints(ind);
        end
    end
end

end