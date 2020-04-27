maxScalePrc = 2;
ACCs = {'X:\IVCAM2_calibration _testing\unitCalibrationData\F0050045\ACC1';...
        'X:\IVCAM2_calibration _testing\unitCalibrationData\F9440611\ACC1';...
        'X:\IVCAM2_calibration _testing\unitCalibrationData\F9440656\ACC1'};
serials = {'F0050045';...
           'F9440611';...
           'F9440656'};
outputHeaddir = 'X:\IVCAM2_calibration _testing\unitsDSMWrappers';
resolutions = [480,640; 768,1024];
for i = 1:numel(ACCs)
    DSMWrapper = OnlineCalibration.Aug.FrameDsmWarper(ACCs{i});
    for r = 1:size(resolutions,1)
        DSMWrapper = DSMWrapper.SetRes(resolutions(r,:));
        for scaleX = linspace(-maxScalePrc,maxScalePrc,21)
            for scaleY = linspace(-maxScalePrc,maxScalePrc,21)
        
                DSMWrapper = DSMWrapper.SetDsmWarp([1+scaleX/100,0],[1+scaleY/100,0]);
                outDir = fullfile(outputHeaddir,serials{i});
                mkdirSafe(outDir);
                filename = sprintf('DSMWrapper_%dx%d_scaleChangeX_%g_scaleChangeY_%g_.bin',resolutions(r,:),scaleX,scaleY);
                filename = fullfile(outDir, filename);
                DSMWrapper.saveDsmWarp(filename);
            end
        end
    end
    
    
end