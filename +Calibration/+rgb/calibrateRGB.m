function [results,rgbTable,rgbPassed] = calibrateRGB(hw, runParams, calibParams, results,fw,fnCalib, fprintff, t)
    rgbTable = zeros(1,112,'uint8');
    fprintff('[-] Calibrating rgb camera to depth... \n');
    rgbPassed = false;
    if runParams.rgb
        try
            Kdepth = hw.getIntrinsics;
            z2mm = hw.z2mm;
            irImSize = hw.streamSize;
            captures = {calibParams.dfz.captures.capture(:).type};
            trainImages = strcmp('train',captures);
            for i=1:length(captures)
                cap = calibParams.dfz.captures.capture(i);
                cap.transformation(1,1) = cap.transformation(1,1)*calibParams.dfz.sphericalScaleFactors(1);
                cap.transformation(2,2) = cap.transformation(2,2)*calibParams.dfz.sphericalScaleFactors(2);
                img = Calibration.aux.CBTools.showImageRequestDialog(hw,1,cap.transformation,sprintf('RGB to Depth - Image %d',i));
%                im(i) = rotFrame180(img);
                % save images for RGB cal
                InputPath = fullfile(tempdir,'RGB'); 
                path = fullfile(InputPath,sprintf('Pose%d',i));
                mkdirSafe(path);
                Calibration.aux.SaveFramesWrapper(hw, 'IC' , 30 , path);  % save images Z and C in sub dir 
            end
            [rgbPassed,rgbTable,results] = RGB_Calib_Calc(InputPath,calibParams,irImSize,Kdepth,z2mm);
        catch ex
            dispEx(ex);
            fprintff('[x] rgb calibration failed with exception, skipping\n');
        end
    else
        fprintff('[?] skipped\n');
    end

end
