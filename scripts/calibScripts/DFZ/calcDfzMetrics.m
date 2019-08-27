function [ avgRes ] = calcDfzMetrics( vertices,gridSize )
params.target.squareSize = 30;
params.camera.zMaxSubMM = 4;
params.camera.K = [730.1642         0  541.5000; 0  711.8812  386.0000 ; 0 0 1];% XGA K
params.gridSize = gridSize;

for i = 1:numel(vertices)
    [~, results, ~] = Validation.metrics.gridInterDist([], params, vertices{i});
    orderedResults.meanError = results.meanError;
    orderedResults.meanAbsHorzScaleError = results.meanAbsHorzScaleError;
    orderedResults.meanAbsVertScaleError = results.meanAbsVertScaleError;
    orderedResults.lineFitMeanRmsErrorTotalHoriz3D = results.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
    orderedResults.lineFitMeanRmsErrorTotalVertic3D = results.lineFit.lineFitMeanRmsErrorTotalVertic3D;
    orderedResults.lineFitMeanRmsErrorTotalHoriz3D = results.lineFit.lineFitMeanRmsErrorTotalHoriz3D;
    orderedResults.lineFitMeanRmsErrorTotalVertic3D = results.lineFit.lineFitMeanRmsErrorTotalVertic3D;
    orderedResults.lineFitMeanRmsErrorTotalHoriz2D = results.lineFit.lineFitMeanRmsErrorTotalHoriz2D;
    orderedResults.lineFitMeanRmsErrorTotalVertic2D = results.lineFit.lineFitMeanRmsErrorTotalVertic2D;
    orderedResults.rmsPlaneFitDist = Validation.metrics.planeFitOnCorners([], params, vertices{i});
    allRes(i) = orderedResults;
end
avgRes.meanError = mean([allRes.meanError]);
avgRes.meanAbsHorzScaleError = mean([allRes.meanAbsHorzScaleError]);
avgRes.meanAbsVertScaleError = mean([allRes.meanAbsVertScaleError]);
avgRes.lineFitMeanRmsErrorTotalHoriz3D = mean([allRes.lineFitMeanRmsErrorTotalHoriz3D]);
avgRes.lineFitMeanRmsErrorTotalVertic3D = mean([allRes.lineFitMeanRmsErrorTotalVertic3D]);
avgRes.lineFitMeanRmsErrorTotalHoriz2D = mean([allRes.lineFitMeanRmsErrorTotalHoriz2D]);
avgRes.lineFitMeanRmsErrorTotalVertic2D = mean([allRes.lineFitMeanRmsErrorTotalVertic2D]);
avgRes.rmsPlaneFitDist = mean([allRes.rmsPlaneFitDist]);

end
