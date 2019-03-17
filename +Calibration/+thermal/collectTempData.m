function [ framesData, info ] = collectTempData(hw,regs,calibParams,runParams,fprintff,maxTime2Wait)

tempSamplePeriod = 60*calibParams.warmUp.warmUpSP;
tempTh = calibParams.warmUp.warmUpTh;
timeBetweenFrames = calibParams.warmUp.timeBetweenFrames;
maxTime2WaitSec = maxTime2Wait*60;

hw.startStream;
prevTmp = hw.getLddTemperature();
prevTime = 0;
startTime = tic;
%% Collect data until temperature doesn't raise any more
finishedHeating = 0; % A unit finished heating when LDD temperature doesn't raise by more than 0.2 degrees between 1 minute and the next


fprintff('[-] Starting heating stage (waiting for diff<%1.1f over %1.1f minutes) ...\n',tempTh,calibParams.warmUp.warmUpSP);
fprintff('Ldd temperatures: %2.2f',prevTmp);

i = 0;
while ~finishedHeating
    i = i + 1;
    tmpData = getFrameData(hw,regs,calibParams);
    tmpData.time = toc(startTime);
    framesData(i) = tmpData;
    if (framesData(i).time - prevTime) >= tempSamplePeriod  || framesData(i).time > maxTime2WaitSec
        finishedHeating = (framesData(i).temp.ldd - prevTmp) < tempTh;
        prevTmp = framesData(i).temp.ldd;
        prevTime = framesData(i).time;
        fprintff(', %2.2f',prevTmp);
        hw.stopStream;
    end
    pause(timeBetweenFrames);
end
fprintff('\n');


heatTimeVec = [framesData.time];
tempVec = [framesData.temp];
tempVec = [tempVec.ldd];

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(heatTimeVec,tempVec)
    title('Heating Stage'); grid on;xlabel('sec');ylabel('ldd temperature [degrees]');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('LddTempOverTime'),1);
end
info.duration = heatTimeVec(end);
info.startTemp = tempVec(1);
info.endTemp = tempVec(end);

end

function [ptsWithZ] = cornersData(frame,regs,calibParams)
if isempty(calibParams.gnrl.cbGridSz)
    pts = reshape(Calibration.aux.CBTools.findCheckerboardFullMatrix(frame.i, 1),[],2);
else
    [pts,gridSize] = Validation.aux.findCheckerboard(frame.i,calibParams.gnrl.cbGridSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    if ~isequal(gridSize, calibParams.gnrl.cbGridSz)
        ptsWithZ = [];
        return;
    end
end
zIm = single(frame.z)/single(regs.GNRL.zNorm);
zPts = interp2(zIm,pts(:,1),pts(:,2));
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
[angx,angy] = Calibration.aux.vec2ang(verts,regs,[]);
ptsWithZ = [rtd,angx,angy,pts,verts];
ptsWithZ(isnan(ptsWithZ(:,1)),:) = nan;
end

function frameData = getFrameData(hw,regs,calibParams)
    frame = hw.getFrame();
    [frameData.temp.ldd,frameData.temp.mc,frameData.temp.ma,frameData.temp.tSense,frameData.temp.vSense] = hw.getLddTemperature;
    frameData.ptsWithZ = cornersData(frame,regs,calibParams);
%         params.camera.zMaxSubMM = 2^double(hw.read('GNRLzMaxSubMMExp'));
%         params.camera.K = (((reshape([typecast(regs.FRMW.kRaw,'single'),1],3,3)')));
%         params.target.squareSize = 30;
%         params.expectedGridSize = [];
%         [score, allRes,dbg] = Validation.metrics.gridInterDist(frame, params);
    
end

