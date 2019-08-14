function [ framesData, info ] = collectTempData(hw,regs,calibParams,runParams,fprintff,maxTime2Wait,app)

tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
maxTime2WaitSec = maxTime2Wait*60;

pN = 1000;
tempsForPlot = nan(1,pN);
timesForPlot = nan(1,pN);
plotDataI = 1;

Calibration.aux.startHwStream(hw,runParams);
if calibParams.gnrl.sphericalMode
    hw.setReg('DIGGsphericalEn',1);
    hw.cmd(sprintf('mwd a0020c00 a0020c04 %x // DIGGsphericalScale',typecast(regs.DIGG.sphericalScale,'uint32')))
%     hw.setReg('DIGGsphericalScale',dec2hex(typecast(regs.DIGG.sphericalScale,'uint32')));
    hw.setReg('DESTdepthAsRange',1);
    hw.setReg('DESTbaseline$',single(0));
    hw.setReg('DESTbaseline2',single(0));
end
hw.cmd('mwd a00e18b8 a00e18bc ffff0000 // JFILinvMinMax');
hw.cmd('mwd a0020834 a0020838 ffffffff // DCORcoarseMasking_002');    
hw.shadowUpdate;

prevTmp = hw.getLddTemperature();
prevTime = 0;
tempsForPlot(plotDataI) = prevTmp;
timesForPlot(plotDataI) = prevTime/60;
plotDataI = mod(plotDataI,pN)+1;

startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next
manualCaptures = isfield(runParams,'manualCaptures') && runParams.manualCaptures;
if manualCaptures
    app.stopWarmUpButton.Visible = 'on';
    app.stopWarmUpButton.Enable = 'on'; 
end

fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);

i = 0;
tempFig = figure(190789);
plot(timesForPlot,tempsForPlot); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));

while ~finishedHeating
    i = i + 1;
    tmpData = getFrameData(hw,regs,calibParams);
    tmpData.time = toc(startTime);
    framesData(i) = tmpData;
    
    if tempFig.isvalid
        tempsForPlot(plotDataI) = framesData(i).temp.ldd;
        timesForPlot(plotDataI) = framesData(i).time/60;
        figure(190789);plot(timesForPlot([plotDataI+1:pN,1:plotDataI]),tempsForPlot([plotDataI+1:pN,1:plotDataI])); xlabel('time(minutes)');ylabel('ldd temp(degrees)');title(sprintf('Heating Progress - %2.2fdeg',tempsForPlot(plotDataI)));drawnow;
        plotDataI = mod(plotDataI,pN)+1;
    end
    if ((framesData(i).time - prevTime) >= tempSamplePeriod)  || (manualCaptures && Calibration.aux.globalSkip(0)) 
        manualSkip = (manualCaptures && Calibration.aux.globalSkip(0));
        reachedRequiredTempDiff = ((framesData(i).temp.ldd - prevTmp) < tempTh);
        reachedTimeLimit = (framesData(i).time > maxTime2WaitSec);
        reachedCloseToTKill = (framesData(i).temp.ldd > calibParams.gnrl.lddTKill-1);
        raisedFarAboveCalibTemp = (framesData(i).temp.ldd > regs.FRMW.dfzCalTmp+calibParams.warmUp.teminationTempdiffFromCalibTemp);
        
        finishedHeating = manualSkip  || ...
                          reachedRequiredTempDiff || ...
                          reachedTimeLimit || ...
                          reachedCloseToTKill || ...
                          raisedFarAboveCalibTemp;
        
        
        prevTmp = framesData(i).temp.ldd;
        prevTime = framesData(i).time;
        fprintff(', %2.2f',prevTmp);
        
    end
    pause(timeBetweenFrames);
    
    if i == 4
        sceneFig = figure(190790);
        imshow(rot90(hw.getFrame().i,2));
        title('Scene Image');
    end
end

if i >=4 && sceneFig.isvalid
    close(sceneFig);
end
if tempFig.isvalid
    close(tempFig);
end

hw.stopStream;
fprintff('Done\n');

if manualSkip
    reason = 'Manual skip';
elseif reachedRequiredTempDiff
    reason = 'Stable temperature';
elseif reachedTimeLimit
    reason = 'Passed time limit';
elseif reachedCloseToTKill
    reason = 'Reached close to TKILL';
elseif raisedFarAboveCalibTemp
    reason = 'Raised far above calib temperature';
end
fprintff('Finished heating reason: %s\n',reason);


heatTimeVec = [framesData.time];
tempVec = [framesData.temp];
LddTempVec = [tempVec.ldd];

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,LddTempVec)
    title('Heating Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('LddTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.ma])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('ma temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MaTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.mc])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('mc temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('McTempOverTime'),1);
    
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,[tempVec.apdTmptr])
    title('Heating Stage'); grid on;xlabel('sec');ylabel('Apd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('ApdTempOverTime'),1);
    
end
info.duration = heatTimeVec(end);
info.startTemp = LddTempVec(1);
info.endTemp = LddTempVec(end);


if manualCaptures
    app.stopWarmUpButton.Visible = 'off';
    app.stopWarmUpButton.Enable = 'off'; 
    Calibration.aux.globalSkip(1,0);
end
end

function [ptsWithZ] = cornersData(frame,regs,calibParams)
if isempty(calibParams.gnrl.cbGridSz)
    [pts,colors] = Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1);
    pts = reshape(pts,[],2);
else
    [pts,gridSize] = Validation.aux.findCheckerboard(frame.i,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
        ptsWithZ = [];
        return;
    end
end
if ~regs.DIGG.sphericalEn
    zIm = single(frame.z)/single(regs.GNRL.zNorm);
    if calibParams.gnrl.sampleRTDFromWhiteCheckers && isempty(calibParams.gnrl.cbGridSz)
        [zPts,~,~,pts,~] = Calibration.aux.CBTools.valuesFromWhitesNonSq(zIm,reshape(pts,20,28,2),colors,1/8);
        pts = reshape(pts,[],2);
    else
        zPts = interp2(zIm,pts(:,1),pts(:,2));
    end
    matKi=(regs.FRMW.kRaw)^-1;
    
    u = pts(:,1)-1;
    v = pts(:,2)-1;
    
    tt=zPts'.*[u';v';ones(1,numel(v))];
    verts=(matKi*tt)';
    
    %% Get r,angx,angy
    if regs.DEST.hbaseline
        rxLocation = [regs.DEST.baseline,0,0];
    else
        rxLocation = [0,regs.DEST.baseline,0];
    end
    rtd = sqrt(sum(verts.^2,2)) + sqrt(sum((verts - rxLocation).^2,2));
    [angx,angy] = Calibration.aux.vec2ang(normr(verts),regs);
    [angx,angy] = Calibration.Undist.inversePolyUndistAndPitchFix(angx,angy,regs);
    ptsWithZ = [rtd,angx,angy,pts,verts];
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
    
else
    rpt = Calibration.aux.samplePointsRtd(frame.z,pts,regs);
    rpt(:,1) = rpt(:,1) - regs.DEST.txFRQpd(1);
    [angxPostUndist,angyPostUndist] = Calibration.Undist.applyPolyUndistAndPitchFix(rpt(:,2),rpt(:,3),regs);
    vUnit = Calibration.aux.ang2vec(angxPostUndist,angyPostUndist,regs)';
    %vUnit = reshape(vUnit',size(d.rpt));
    %vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    if regs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    rtd_=rpt(:,1);
    r = (0.5*(rtd_.^2 - 100))./(rtd_ - 10.*sing);
    v = double(vUnit.*r);
    ptsWithZ = [rpt,reshape(pts,[],2),v];
    ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
end
end

function frameData = getFrameData(hw,regs,calibParams)
    frame = hw.getFrame();
    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.apdTmptr] = hw.getLddTemperature;
    frameData.temp.humidity = hw.getHumidityTemperature;
%     frameData.pzrShifts = hw.pzrShifts;
    [frameData.iBias(1), frameData.vBias(1)] = hw.pzrPowerGet(1,5);
    [frameData.iBias(2), frameData.vBias(2)] = hw.pzrPowerGet(2,5);
    [frameData.iBias(3), frameData.vBias(3)] = hw.pzrPowerGet(3,5);
    frameData.ptsWithZ = cornersData(frame,regs,calibParams);
    
%     params.camera.zMaxSubMM = 4;
%     params.camera.K = regs.FRMW.kRaw;
%     params.target.squareSize = 30;
%     params.expectedGridSize = [9,13];
%     [frameData.eGeom, allRes,dbg] = Validation.metrics.gridInterDist(frame, params);
    
end

