function collectTempData(fwPath)
fw = Pipe.loadFirmware(fwPath);
regs = fw.get();
outputDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014';
tempTh = 0.2; 
tempSamplePer = 60;
iter = 0;
N = 3;
hw = HWinterface;
hw.cmd('DIRTYBITBYPASS');
hw.cmd('algo_thermloop_en 0');
hw.setReg('DESTtmptrOffset',single(0));
hw.shadowUpdate;
while 1
    hw.startStream;
    hw.getFrame(10);
    prevTmp = hw.getLddTemperature();
    prevTime = 0;
    tic;
    %% Collect data until temperature doesn't raise any more
    finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
    fnum = 0;
    while ~finishedHeating
        frameData = getNFrame(hw,regs,N);
        

        saveFrameData(frameData,outputDir,iter,fnum);
        fnum = fnum + N;
        if (frameData(N).time - prevTime) >= tempSamplePer
            finishedHeating = (frameData(N).temp.ldd - prevTmp) < tempTh;
            prevTmp = frameData(N).temp.ldd;
            prevTime = frameData(N).time;
        end
    end

    %% Let unit cool down
    hw.stopStream;
    finishedCooling = 0;
    coolTimeVec(1) = toc;
    [coolTmpVec(1,1),coolTmpVec(1,2),coolTmpVec(1,3),coolTmpVec(1,4),coolTmpVec(1,5)] = hw.getLddTemperature;
    while ~finishedCooling
        pause(tempSamplePer);
        coolTimeVec(end+1) = toc;
        newI = size(coolTmpVec,1)+1;
        [coolTmpVec(newI,1),coolTmpVec(newI,2),coolTmpVec(newI,3),coolTmpVec(newI,4),coolTmpVec(newI,5)] = hw.getLddTemperature;

        if coolTmpVec(newI-1,1) - coolTmpVec(newI,1) < tempTh
            finishedCooling = 1;
        end
    end
    saveCoolingStageRes(coolTimeVec,coolTmpVec,outputDir,iter);

    %% Prepare for next cycle
    iter = iter + 1;
    clearvars -except hw iter tempTh tempSamplePer fw regs outputDir N
    pack;
    
    sendolmail('mundtal1@gmail.com',sprintf('Iteration %d finished',iter),'Test update');
end

end
function saveCoolingStageRes(coolTimeVec,coolTmpVec,outputDir,iter)
    subDir = fullfile(outputDir,sprintf('iter_%04d',iter));
    fname = fullfile(subDir,'coolingLog.mat');
    coolingTable = [coolTimeVec(:),coolTmpVec];
    save(fname,'coolingTable');
end
function saveFrameData(frameData,outputDir,iter,fnum)
    
    subDir = fullfile(outputDir,sprintf('iter_%04d',iter));
    mkdirSafe(subDir);
    for i = 1:numel(frameData)
        fname = fullfile(subDir,sprintf('frameData_%05d.mat',fnum+i-1));
        frame = frameData(i);
        save(fname,'frame');
    end
end
function frameData_ = getNFrame(hw,regs,N)
    frame = hw.getFrame(N,0);
    for i = 1:N
        [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.tSense,frameData.temp.vSense] = hw.getLddTemperature;
        frameData.pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame(i).i, 1);
        frameData.rpt = Calibration.aux.samplePointsRtd(frame(i).z,frameData.pts,regs);
        frameData.time = toc;
        frameData_(i) = frameData;
    end
end