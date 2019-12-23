debug = false;
baseFoldr = 'C:\temp\torture';
testFolderName = datestr(now,'mmddHHMM');
testFolder = fullfile(baseFoldr, testFolderName);
mkdirSafe(testFolder);
if exist('log', 'var')
    log.closeLogger();
end
log= Log.getLogger(testFolder);
initialFrameCapture = 900;
framesPerMinute = 5;
zResolution = [480 640];
rgbResolution = [1920 1080];
streamRange = [2 30];
restRange = [2 30];
if debug
    streamRange = [1 2];
    restRange = [1 2];
end

log.debug(sprintf('zResolution: %d %d',zResolution(1),zResolution(2)), 'init');
log.debug(sprintf('rgbResolution: %d %d',rgbResolution(1),rgbResolution(2)), 'init');
log.debug(sprintf('streamRange: %d %d',streamRange(1),streamRange(2)), 'init');
log.debug(sprintf('restRange: %d %d',restRange(1),restRange(2)), 'init');


camera = struct();
hw = HWinterface();
[ ~,b] = hw.cmd('RGB_INTRINSICS_GET');
intr = typecast(b,'single');
Krgb = eye(3);
Krgb([1,5,7,8,4]) = intr([6:9,1]);%intr([6:9,1]);
drgb = intr(10:14);
[ ~,b] = hw.cmd('RGB_EXTRINSICS_GET');
extr = typecast(b,'single');
Rrgb = reshape(extr(1:9),[3 3])';
Trgb = extr(10:12)';

camera.zK = hw.getIntrinsics();
camera.zMaxSubMM = hw.z2mm;
camera.rgbResolution = rgbResolution;
camera.rgbK = Krgb;
camera.rgbT = Trgb;
camera.rgbPmat = Krgb*[Rrgb Trgb];
camera.rgbDistort = drgb;
camera.Krgb = Krgb;
camera.zResolution = zResolution;

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
    
    hw = HWinterface();
    tic;
    tempStrat=struct();
    [tempStrat.lddTmptr,tempStrat.mcTmptr,tempStrat.maTmptr,tempStrat.apdTmptr] = hw.getLddTemperature();
    tempStrat.humTmpr = hw.getHumidityTemperature();
    log.info(sprintf('temp (stratStream): lddTmptr: %f, mcTmptr: %f, maTmptr: %f, apdTmptr: %f, humTmpr: %f',tempStrat.lddTmptr,tempStrat.mcTmptr,tempStrat.maTmptr,tempStrat.apdTmptr,tempStrat.humTmpr) ,location);
    hw.startStream(false, zResolution, rgbResolution);
    if ~debug
        frames = hw.getFrame(initialFrameCapture, false);
        rgbFrames = hw.getColorFrame(initialFrameCapture);
    else
        frames = hw.getFrame(30, false);
        rgbFrames = hw.getColorFrame(30);
    end
    while streamTime > toc/60
        frames = [frames hw.getFrame(framesPerMinute, false)];
        rgbFrames =[rgbFrames hw.getColorFrame(framesPerMinute)];
        pause(60);
    end
    tempEnd=struct();
    [tempEnd.lddTmptr,tempEnd.mcTmptr,tempEnd.maTmptr,tempEnd.apdTmptr] = hw.getLddTemperature();
    tempEnd.humTmpr = hw.getHumidityTemperature();
    log.info(sprintf('temp (endStream): lddTmptr: %f, mcTmptr: %f, maTmptr: %f, apdTmptr: %f, humTmpr: %f',tempEnd.lddTmptr,tempEnd.mcTmptr,tempEnd.maTmptr,tempEnd.apdTmptr,tempEnd.humTmpr) ,location);
    for i = 1:length(frames)
        frames(i).rgb = rgbFrames(i).color;
    end
    save(fullfile(testFolder, sprintf('itaretion_%0.5d',counter)), 'frames','tempStrat', 'tempEnd','-v7.3');
    hw.stopStream();
    hw.cmd('rst');
    pause(restTime*60);
    log.info(sprintf('end iteration: %d', counter), location);
    counter = counter + 1;
end