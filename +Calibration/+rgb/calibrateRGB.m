function [results,rgbTable,rgbPassed] = calibrateRGB(hw, runParams, calibParams, results,fnCalib, fprintff, t)
    rgbTable = zeros(1,112,'uint8');
    fprintff('[-] Calibrating rgb camera to depth... \n');
    rgbPassed = false;
    if runParams.rgb
        try
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

                % save images for RGB cal
                InputPath = fullfile(ivcam2tempdir,'RGB'); 
                path = fullfile(InputPath,sprintf('Pose%d',i));
                mkdirSafe(path);
                Calibration.aux.SaveFramesWrapper(hw, 'ICZ' , 30 , path);  % save images Z and C in sub dir 
            end
            fprintff('\n');
            [rgbPassed,rgbTable,resultsRGB] = RGB_Calib_Calc(InputPath,calibParams,irImSize,Kdepth,z2mm);
            results = Validation.aux.mergeResultStruct(results,resultsRGB);
        catch ex
            fprintff('[!] ERROR:%s\n',strtrim(ex.message));
            fprintff('[!] Error in :%s (line %d)\n',strtrim(ex.stack(1).name),ex.stack(1).line);
            fprintff('[x] rgb calibration failed with exception, skipping\n');
        end
    else
        fprintff('[?] skipped\n');
    end

end
