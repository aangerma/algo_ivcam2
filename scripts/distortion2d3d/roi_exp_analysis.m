clear variables
clc

%% Post processing

load('roi_exp_results.mat')
lineFitFields = fieldnames(results{1}(1).res.lineFit);
planeFitFields = fieldnames(results{1}(1).res.planeFit);
scaleErrFields = fieldnames(results{1}(1).res.scaleErr);
for iCal=1:length(results)
    for iMethod=1:length(results{1})
        runTime(iCal,iMethod)=results{iCal}(iMethod).runTime;
        geomErr(iCal,iMethod)=results{iCal}(iMethod).res.geomErr;
        for iField = 1:length(lineFitFields)
            eval(sprintf('%s(iCal,iMethod)=results{iCal}(iMethod).res.lineFit.%s;', lineFitFields{iField}, lineFitFields{iField}))
        end
        for iField = 1:length(planeFitFields)
            eval(sprintf('%s(iCal,iMethod)=results{iCal}(iMethod).res.planeFit.%s;', planeFitFields{iField}, planeFitFields{iField}))
        end
        for iField = 1:length(scaleErrFields)
            eval(sprintf('%s(iCal,iMethod)=results{iCal}(iMethod).res.scaleErr.%s;', scaleErrFields{iField}, scaleErrFields{iField}))
        end
        for iCrop = 1:length(cropRatiosForEval)
            geomErrCropped(iCal,iMethod,iCrop)=results{iCal}(iMethod).res.geomErrForEval{iCrop};
            for iField = 1:length(lineFitFields)
                eval(sprintf('%sCropped(iCal,iMethod,iCrop)=results{iCal}(iMethod).res.lineFitForEval{iCrop}.%s;', lineFitFields{iField}, lineFitFields{iField}))
            end
            for iField = 1:length(planeFitFields)
                eval(sprintf('%sCropped(iCal,iMethod,iCrop)=results{iCal}(iMethod).res.planeFitForEval{iCrop}.%s;', planeFitFields{iField}, planeFitFields{iField}))
            end
            for iField = 1:length(scaleErrFields)
                eval(sprintf('%sCropped(iCal,iMethod,iCrop)=results{iCal}(iMethod).res.scaleErrForEval{iCrop}.%s;', scaleErrFields{iField}, scaleErrFields{iField}))
            end
        end
    end
end
geomErr(end+1,:)=median(geomErr(1:6,:),1);
geomErr(end+1,:)=max(geomErr(1:6,:),[],1);
geomErrCropped(end+1,:,:)=median(geomErrCropped(1:6,:,:),1);
geomErrCropped(end+1,:,:)=max(geomErrCropped(1:6,:,:),[],1);
for iField = 1:length(lineFitFields)
    eval(sprintf('%s(end+1,:,:)=median(%s(1:6,:,:),1);', lineFitFields{iField}, lineFitFields{iField}))
    eval(sprintf('%s(end+1,:,:)=max(%s(1:6,:,:),[],1);', lineFitFields{iField}, lineFitFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=median(%sCropped(1:6,:,:),1);', lineFitFields{iField}, lineFitFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=max(%sCropped(1:6,:,:),[],1);', lineFitFields{iField}, lineFitFields{iField}))
end
for iField = 1:length(planeFitFields)
    eval(sprintf('%s(end+1,:,:)=median(%s(1:6,:,:),1);', planeFitFields{iField}, planeFitFields{iField}))
    eval(sprintf('%s(end+1,:,:)=max(%s(1:6,:,:),[],1);', planeFitFields{iField}, planeFitFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=median(%sCropped(1:6,:,:),1);', planeFitFields{iField}, planeFitFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=max(%sCropped(1:6,:,:),[],1);', planeFitFields{iField}, planeFitFields{iField}))
end
for iField = 1:length(scaleErrFields)
    eval(sprintf('%s(end+1,:,:)=median(%s(1:6,:,:),1);', scaleErrFields{iField}, scaleErrFields{iField}))
    eval(sprintf('%s(end+1,:,:)=max(%s(1:6,:,:),[],1);', scaleErrFields{iField}, scaleErrFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=median(%sCropped(1:6,:,:),1);', scaleErrFields{iField}, scaleErrFields{iField}))
    eval(sprintf('%sCropped(end+1,:,:)=max(%sCropped(1:6,:,:),[],1);', scaleErrFields{iField}, scaleErrFields{iField}))
end

%% Run times

meanRunTimeOld = mean(vec(runTime(:,1)));
meanRunTimeNew = mean(vec(runTime(:,2:end)));
fprintf('Run time: %.1f[sec] (old school) vs. %.1f[sec] (new)\n', meanRunTimeOld, meanRunTimeNew)

%% Calib ROI

res = [1024,768];
ttl = {'DFZ only (old school)', 'DFZ+TPS, full ROI', 'DFZ+TPS, square ROI', 'DFZ+TPS, horz rect ROI', 'DFZ+TPS, vert rect ROI', 'DFZ+TPS, plus ROI'};
figure
for iMethod=1:length(results{1})
    subplot(2,3,iMethod)
    hold all
    patch([-0.5,-0.5,0.5,0.5,-0.5]*res(1)+0.5*res(1), [-0.5,0.5,0.5,-0.5,-0.5]*res(2)+0.5*res(2), 'b', 'linestyle','none')
    cropRatios=results{1}(iMethod).cropRatios;
    if isempty(cropRatios)
        patch([-0.5,-0.5,0.5,0.5,-0.5]*res(1)+0.5*res(1), [-0.5,0.5,0.5,-0.5,-0.5]*res(2)+0.5*res(2), 'g', 'linestyle','none')
    else
        for iRoi=1:size(cropRatios,1)
            patch([-0.5,-0.5,0.5,0.5,-0.5]*res(1)*(1-2*cropRatios(iRoi,1))+0.5*res(1), [-0.5,0.5,0.5,-0.5,-0.5]*res(2)*(1-2*cropRatios(iRoi,2))+0.5*res(2), 'g', 'linestyle','none')
        end
    end
    title(sprintf('%d: %s', iMethod, ttl{iMethod}))
end

%% Performance for all cal ROI and specific val ROI

rows = [7,8];
unitsStat = {'median', 'max'};
iRoi = 4;
for iPlot = 1:2
    iRow = rows(iPlot);
    
    figure
    subplot(2,2,1)
    hold all
    plot(geomErr(iRow,:), 'o-')
    plot(lineFitMeanRmsErrorTotalHoriz2D(iRow,:), 'o-')
    plot(lineFitMeanRmsErrorTotalVertic2D(iRow,:), 'o-')
    plot(lineFitMeanRmsErrorTotalHoriz3D(iRow,:), 'o-')
    plot(lineFitMeanRmsErrorTotalVertic3D(iRow,:), 'o-')
    plot(rmsPlaneFitDist(iRow,:), 'o-')
    %plot(maxPlaneFitDist(iRow,:), 'o-')
    grid on, xlabel('Method/ROI'), ylabel('measure')
    title(['Performance on full ROI, ', unitsStat{iPlot}, ' over units'])
    legend('GID', 'line fit 2D horz RMS', 'line fit 2D vert RMS', 'line fit 3D horz RMS', 'line fit 3D vert RMS', 'plane fit RMS')
    ylim([0 1.2])
    
    subplot(2,2,3)
    hold all
    plot(meanAbsHorzScaleError(iRow,:), 'o-')
    plot(meanAbsVertScaleError(iRow,:), 'o-')
    grid on, xlabel('Method/ROI'), ylabel('measure')
    title(['Performance on full ROI, ', unitsStat{iPlot}, ' over units'])
    legend('scale error horz mean abs', 'scale error vert mean abs')
    ylim([0 0.02])
    
    subplot(2,2,2)
    hold all
    plot(geomErrCropped(iRow,:,iRoi), 'o-')
    plot(lineFitMeanRmsErrorTotalHoriz2DCropped(iRow,:,iRoi), 'o-')
    plot(lineFitMeanRmsErrorTotalVertic2DCropped(iRow,:,iRoi), 'o-')
    plot(lineFitMeanRmsErrorTotalHoriz3DCropped(iRow,:,iRoi), 'o-')
    plot(lineFitMeanRmsErrorTotalVertic3DCropped(iRow,:,iRoi), 'o-')
    plot(rmsPlaneFitDistCropped(iRow,:,iRoi), 'o-')
    %plot(maxPlaneFitDistCropped(iRow,:,iRoi), 'o-')
    grid on, xlabel('Method/ROI'), ylabel('measure')
    title(['Performance on small ROI, ', unitsStat{iPlot}, ' over units'])
    legend('GID', 'line fit 2D horz RMS', 'line fit 2D vert RMS', 'line fit 3D horz RMS', 'line fit 3D vert RMS', 'plane fit RMS')
    ylim([0 1.2])
    
    subplot(2,2,4)
    hold all
    plot(meanAbsHorzScaleErrorCropped(iRow,:,iRoi), 'o-')
    plot(meanAbsVertScaleErrorCropped(iRow,:,iRoi), 'o-')
    grid on, xlabel('Method/ROI'), ylabel('measure')
    title(['Performance on full ROI, ', unitsStat{iPlot}, ' over units'])
    legend('scale error horz mean abs', 'scale error vert mean abs')
    ylim([0 0.02])
end

%%

res = [1024,768];
figure
plot([-0.5,-0.5,0.5,0.5,-0.5]*res(1)+0.5*res(1), [-0.5,0.5,0.5,-0.5,-0.5]*res(2)+0.5*res(2))
grid on
for iCrop = 1:length(cropRatiosForEval)
    hold all
    plot([-0.5,-0.5,0.5,0.5,-0.5]*res(1)*(1-2*cropRatiosForEval{iCrop}(1))+0.5*res(1), [-0.5,0.5,0.5,-0.5,-0.5]*res(2)*(1-2*cropRatiosForEval{iCrop}(2))+0.5*res(2),'r')
    r = (1-2*cropRatiosForEval{iCrop}(1))*(1-2*cropRatiosForEval{iCrop}(2));
    text(0.5*res(1)-50, 0.5*res(2)*(1-2*cropRatiosForEval{iCrop}(2))+0.5*res(2), sprintf('%d: %d%% ROI', iCrop, round(100*r)))
end

%%

iRow = 7;
iCol = 2; % calibration on full ROI

figure
subplot(1,2,1)
hold all
plot(squeeze(geomErrCropped(iRow,iCol,:)), 'o-')
plot(squeeze(lineFitMeanRmsErrorTotalHoriz2DCropped(iRow,iCol,:)), 'o-')
plot(squeeze(lineFitMeanRmsErrorTotalVertic2DCropped(iRow,iCol,:)), 'o-')
plot(squeeze(lineFitMeanRmsErrorTotalHoriz3DCropped(iRow,iCol,:)), 'o-')
plot(squeeze(lineFitMeanRmsErrorTotalVertic3DCropped(iRow,iCol,:)), 'o-')
plot(squeeze(rmsPlaneFitDistCropped(iRow,iCol,:)), 'o-')
%plot(squeeze(maxPlaneFitDistCropped(iRow,:,iRoi)), 'o-')
grid on, xlabel('validation ROI'), ylabel('measure')
legend('GID', 'line fit 2D horz RMS', 'line fit 2D vert RMS', 'line fit 3D horz RMS', 'line fit 3D vert RMS', 'plane fit RMS')
ylim([0 1])

subplot(1,2,2)
hold all
plot(squeeze(meanAbsHorzScaleErrorCropped(iRow,iCol,:)), 'o-')
plot(squeeze(meanAbsVertScaleErrorCropped(iRow,iCol,:)), 'o-')
grid on, xlabel('validation ROI'), ylabel('measure')
legend('scale error horz mean abs', 'scale error vert mean abs')
ylim([0 0.01])

sgtitle('Performance on validation ROI, median over units')

