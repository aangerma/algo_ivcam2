function collectTempData(fwPath)
fw = Pipe.loadFirmware(fwPath);
regs = fw.get();
outputDir = 'X:\Data\IvCam2\temperaturesData\rptCollection';
tempTh = 0.2; 
tempSamplePer = 60;
iter = 0;
hw = HWinterface;
hw.cmd('algo_thermloop_en 0');
hw.startStream;
hw.setReg('DESTtmptrOffset',single(0));
hw.shadowUpdate;
tic; % Start measuring time

while 1
    prevTmp = hw.getLddTemperature;

    %% Collect data until temperature doesn't raise any more
    finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
    fnum = 0;
    while ~finishedHeating
        frameData = get1Frame(hw,regs);
        frameData.time = toc;

        saveFrameData(frameData,outputDir,iter,fnum);
        fnum = fnum + 1;
        if (frameData.time - prevTime) >= tempSamplePer
            finishedHeating = (frameData.currTmp - prevTmp) < tempTh;
            prevTime = frameData.time;
        end
    end

    %% Let unit cool down
    hw.stopStream;
    finishedCooling = 0;
    coolTimeVec(1) = toc;
    coolTmpVec(1) = hw.getLddTemperature;
    while ~finishedCooling
        pause(tempSamplePer);
        coolTimeVec(end+1) = toc;
        coolTmpVec(end+1) = hw.getLddTemperature;

        if coolTmpVec(end-1) - coolTmpVec(end) < tempTh
            finishedCooling = 1;
        end
    end
    saveCoolingStageRes(coolTimeVec,coolTmpVec,outputDir,iter);

    %% Prepare for next cycle
    iter = iter + 1;
    clearvars -except hw iter tempTh tempSamplePer fw regs outputDir
    pack;
    
    sendolmail('mundtal1@gmail.com',sprintf('Iteration %d finished',iter),'Test update');
end

end
function saveCoolingStageRes(coolTimeVec,coolTmpVec,outputDir,iter)
    subDir = fullfile(outputDir,sprintf('iter_%04d',iter));
    fname = fullfile(subDir,'coolingLog.mat');
    coolingTable = [coolTimeVec(:),coolTmpVec(:)];
    save(fname,'coolingTable');
end
function saveFrameData(frameData,outputDir,iter,fnum)
    subDir = fullfile(outputDir,sprintf('iter_%04d',iter));
    mkdirSafe(subDir);
    fname = fullfile(subDir,sprintf('frameData_%05d.mat',fnum));
    save(fname,'frameData');
end

function frameData = get1Frame(hw,regs)
    frame = hw.getFrame();
    frameData.currTmp = hw.getLddTemperature;
    
    frameData.pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1);
    frameData.rpt = Calibration.aux.samplePointsRtd(frame.z,frameData.pts,regs);
end