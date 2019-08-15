function [outResults] = calibrateExtrinsic(camsData,calibParams)
outResults=[]; 
originIndex=calibParams.gnrl.originCamera;
camsAnalysis=cell(size(camsData)) ; outResults=cell(size(camsData));
%% analyze data
for i=1:length(camsData)
    data=camsData{i}; 
    % detect checkres corners 
    [camsAnalysis{i}.gridPoints,camsAnalysis{i}.gridSize] = Validation.aux.findCheckerboard(double(data.Frames(1).i), []);
    % convert to point cloud 
    camsAnalysis{i}.vert= (Validation.aux.pointsToVertices(camsAnalysis{i}.gridPoints-1, double(data.Frames(1).z), data.params))';
    % detect markers and find offset
    [camsAnalysis{i}.targetOffset] =  Calibration.L520extrinsicCalib.detectMarkersAndFindOffset(calibParams,data.Frames(1).i,data.Frames(1).z,camsAnalysis{i}.vert',data.params);
    % build GT checkres
    [camsAnalysis{i}.gtV] =  Calibration.L520extrinsicCalib.buidGTcheckers(camsAnalysis{i}.gridSize,camsAnalysis{i}.targetOffset,calibParams.target.cbSquareSz); 
    % rigid fit - camera data to GT
    [camsAnalysis{i}.err,camsAnalysis{i}.fitted2GTspace,camsAnalysis{i}.rotmat,camsAnalysis{i}.GTtranslation,camsAnalysis{i}.camTranslation] =  Calibration.L520extrinsicCalib.rigidFit(camsAnalysis{i}.gtV',camsAnalysis{i}.vert');
end 

end

