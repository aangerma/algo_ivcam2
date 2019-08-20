clear variables
clc

%%

calPath = '\\143.185.124.250\tester data\IDC Data\IVCAM\L515\Calibration\BIG PBS\HENG-2360\';
calFolders = {'F9220005\Algo1 3.05.0\mat_files\', 'F9220006\Algo1 3.05.0\mat_files\', 'F9220056\Algo1 3.05.0\mat_files\',...
    'F9220065\Algo1 3.05.0\mat_files\', 'F9240054\Algo1 3.05.0 cal\mat_files\', 'F9240086\algo1 3.05.0 cal\mat_files\'};

%%

nCal = length(calFolders);
for iCal = 1:nCal
    %
    fprintf('--->>> Analyzing data from calibration folder #%d...\n',iCal)
    load([calPath, calFolders{iCal}, 'DFZ_im.mat']);
    load([calPath, calFolders{iCal}, 'DFZ_Calib_Calc_in.mat']);
    %
    mainPath = 'tmp\';
    subPaths = {'Pose1', 'Pose1_SR', 'Pose2', 'Pose3', 'Pose4', 'Pose5'};
    fprintf('Writing BIN files...\n')
    for iPose = 1:length(im)
        curSubPath = [mainPath, subPaths{iPose}];
        mkdirSafe(curSubPath);
        for iFrame = 0:9
            fn_I = fullfile(curSubPath ,['I' sprintf('_%04d.bin',iFrame)]);
            fn_Z = fullfile(curSubPath ,['Z' sprintf('_%04d.bin',iFrame)]);
            writeAllBytes(uint8(im(iPose).i(:)), fn_I);
            writeAllBytes(typecast(uint16(im(iPose).z(:)),'uint8'), fn_Z);
        end
    end
    fprintff = @fprintf;
    calibParams.dfz.Kfor2dError = single([713.8419, 0, 527.0000;   0, 711.6800, 388.0000;   0, 0, 1.0000]);
    calibParams.dfz.sampleRTDFromWhiteCheckers = 1;
    calibParams.dfz.cropRatiosForEval = {[0.45 0.45],[0.40 0.40],[0.35 0.35],[0.30 0.30],[0.25 0.25],[0.20 0.20],[0.15 0.15],[0.10 0.10],[0.05 0.05]};
    % 
    fprintf('>>> Running DFZ old school...\n')
    clear resultsPerCal
    calibParams.dfz.performRegularDFZWithoutTPS = 1;
    calibParams.dfz.cropRatios = [0 0];
    t0 = tic;
    [~,~,resultsPerCal(1).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(1).runTime = toc(t0);
    resultsPerCal(1).cropRatios = [];
    % 
    fprintf('>>> Running DFZ with full ROI...\n')
    calibParams.dfz.performRegularDFZWithoutTPS = 0;
    calibParams.dfz.calibrateOnlyCropped = 0;
    calibParams.dfz.cropRatios = [0 0];
    t0 = tic;
    [~,~,resultsPerCal(2).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(2).runTime = toc(t0);
    resultsPerCal(2).cropRatios = calibParams.dfz.cropRatios;
    % 
    fprintf('>>> Running DFZ with medium square ROI...\n')
    calibParams.dfz.cropRatios = [0.33 0.3];
    t0 = tic;
    [~,~,resultsPerCal(3).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(3).runTime = toc(t0);
    resultsPerCal(3).cropRatios = calibParams.dfz.cropRatios;
    % 
    fprintf('>>> Running DFZ with horizontal rect ROI...\n')
    calibParams.dfz.cropRatios = [0.05 0.3];
    t0 = tic;
    [~,~,resultsPerCal(4).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(4).runTime = toc(t0);
    resultsPerCal(4).cropRatios = calibParams.dfz.cropRatios;
    % 
    fprintf('>>> Running DFZ with vertical rect ROI...\n')
    calibParams.dfz.cropRatios = [0.33 0.05];
    t0 = tic;
    [~,~,resultsPerCal(5).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(5).runTime = toc(t0);
    resultsPerCal(5).cropRatios = calibParams.dfz.cropRatios;
    % 
    fprintf('>>> Running DFZ with plus-shaped ROI...\n')
    calibParams.dfz.cropRatios = [0.05 0.3; 0.33 0.05];
    t0 = tic;
    [~,~,resultsPerCal(6).res] = DFZ_Calib_Calc_int_copy(mainPath, [], mainPath, calibParams, fprintff, regs);
    resultsPerCal(6).runTime = toc(t0);
    resultsPerCal(6).cropRatios = calibParams.dfz.cropRatios;
    % 
    cropRatiosForEval = calibParams.dfz.cropRatiosForEval;
    results{iCal} = resultsPerCal;
    rmdir('tmp\','s')
end
save('roi_exp_results.mat', 'cropRatiosForEval', 'results', 'calPath', 'calFolders')


