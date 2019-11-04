function [results,rgbTable,rgbPassed] = calibrateRGB(hw, runParams, calibParams, results,fnCalib, fprintff, t)
rgbTable = zeros(1,112,'uint8');
fprintff('[-] Calibrating rgb camera to depth... \n');
rgbPassed = false;
if runParams.rgb
    Kdepth = hw.getIntrinsics;
    z2mm = hw.z2mm;
    irImSize = hw.streamSize;
    hw.startStream(0,runParams.calibRes);
    captures = {calibParams.dfz.captures.capture(:).type};
    captures = captures(~strcmp(captures,'shortRange'));
    tmpcalibParams.dfz.captures.capture = calibParams.dfz.captures.capture(~strcmp(captures,'shortRange'));
    fprintff('Collecting images for RGB calibration: ');
    for i=1:length(captures)
        fprintff('%s',num2str(i));
        cap = tmpcalibParams.dfz.captures.capture(i);
        cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
        cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
        img = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('RGB to Depth - Image %d',i));
        %                im(i) = rotFrame180(img);
        
        % capture images for RGB cal
        [depthData, rgbData] = captureFramesWrapper(hw, 'ICZ', 30);
    end
    fprintff('\n');
    [rgbPassed,rgbTable,resultsRGB] = RGB_Calib_Calc(depthData, rgbData, calibParams,irImSize,Kdepth,z2mm);
    results = Validation.aux.mergeResultStruct(results,resultsRGB);
    
else
    fprintff('[?] skipped\n');
end

end
