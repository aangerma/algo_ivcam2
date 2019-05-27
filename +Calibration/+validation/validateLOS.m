function [losResults,allResults,frames,dbgData] = validateLOS(hw,runParams,validationParams,expectedGridSize,fprintff)
    %VALIDATELOS Summary of this function goes here
    %   Detailed explanation goes here
    losResults = struct;
    
    
    if ~exist('validationParams','var') || isempty(validationParams)
        validationParams.numOfFrames = 100;
        validationParams.sphericalMode = 1;
    end
    
    if ~exist('fprintff','var')
        fprintff = [];
    end
    
    r=Calibration.RegState(hw);
    r.add('DIGGsphericalEn',logical(validationParams.sphericalMode));
    r.set();
    pause(0.1);
    
%     params = Validation.aux.defaultMetricsParams();
%     params.verbose = 0;
%     params.expectedGridSize = expectedGridSize;
%     params.calibrationTargetIV2 = 1;
    
    frames = hw.getFrame(validationParams.numOfFrames,false,0);
    [losResults,allResults,dbgData] = Calibration.validation.LOSCalc(frames,runParams,expectedGridSize,fprintff);
    r.reset();
end
