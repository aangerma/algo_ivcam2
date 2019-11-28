debug = false;
baseFoldr = 'C:\temp\torture';
testFolderName = datestr(now,'mmddHHMM');
testFolder = fullfile(baseFoldr, testFolderName);
mkdirSafe(testFolder);
if exist('log', 'var')
    log.closeLogger()
end
log= Log.getLogger(testFolder);



resolution = [480 640];
streamRange = [2 30];
restRange = [2 30];
if debug
    streamRange = [0 2];
    restRange = [0 2];
end

log.debug(sprintf('resolution: %d %d',resolution(1),resolution(2)), 'init');
log.debug(sprintf('streamRange: %d %d',streamRange(1),streamRange(2)), 'init');
log.debug(sprintf('restRange: %d %d',restRange(1),restRange(2)), 'init');


camera = struct();
hw = HWinterface();
camera.zK = hw.getIntrinsics();
camera.zMaxSubMM = hw.z2mm;
save(fullfile(testFolder, 'cameraParams'), 'camera');
log.info('take camera intrinsics', 'init');

counter = 1;
toContinue = true;
while toContinue
    location = sprintf('iteration: %d', counter);
    log.info(sprintf('start iteration: %d', counter), location);
    streamTime = randi(streamRange);
    restTime = randi(restRange);
    log.info(sprintf('streamTime: %d, restTime: %d', streamTime, restTime), location);
    
    tic;
    tempStrat=struct();
    [tempStrat.lddTmptr,tempStrat.mcTmptr,tempStrat.maTmptr,tempStrat.apdTmptr] = hw.getLddTemperature();
    tempStrat.humTmpr = hw.getHumidityTemperature();
    log.info(sprintf('temp (stratStream): lddTmptr: %f, mcTmptr: %f, maTmptr: %f, apdTmptr: %f, humTmpr: %f',tempStrat.lddTmptr,tempStrat.mcTmptr,tempStrat.maTmptr,tempStrat.apdTmptr,tempStrat.humTmpr) ,location);
    hw.startStream(false, resolution);
    frames = hw.getFrame(1800, false);
    if debug
        frames = hw.getFrame(30, false);
    end
    while streamTime > toc/60
        frames = [frames hw.getFrame(5, false)];
        pause(60);
    end
    tempEnd=struct();
    [tempEnd.lddTmptr,tempEnd.mcTmptr,tempEnd.maTmptr,tempEnd.apdTmptr] = hw.getLddTemperature();
    tempEnd.humTmpr = hw.getHumidityTemperature();
    log.info(sprintf('temp (endStream): lddTmptr: %f, mcTmptr: %f, maTmptr: %f, apdTmptr: %f, humTmpr: %f',tempEnd.lddTmptr,tempEnd.mcTmptr,tempEnd.maTmptr,tempEnd.apdTmptr,tempEnd.humTmpr) ,location);
    save(fullfile(testFolder, sprintf('itaretion_%0.5d',counter)), 'frames','tempStrat', 'tempEnd');
    hw.stopStream();
    pause(restTime*60);
    log.info(sprintf('end iteration: %d', counter), location);
    counter = counter + 1;
end