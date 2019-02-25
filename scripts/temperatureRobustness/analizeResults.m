dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_latest';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_third_trial';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0021_Regular_24_2_num_2';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0093_25_2';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0093_25_2_num_2';
[frames,coolingStage] = loadDataSet(dataSetDir);
regsPath = fullfile(dataSetDir,'regs.mat');
regs = load(regsPath); regs = regs.regs;
regs.DEST.tmptrOffset = -27.5536;
regs.DEST.tmptrOffset = 0;

%% plot temperature over time
plotTemperature(frames,coolingStage);

%% plot rtd,angx,angy over time
plotEGeom(frames,coolingStage,regs);

%% Show Los Error
% Group frames for each ldd temperature - compute los metric. Once for all,
% and one is the mean for each trial seperately.
tmpBinEdges = (25:0.5:70) - 0.25;
framesPerTemperature = groupFramesByTemp(frames,25:0.5:70,'ldd');
refTmp = typecast(regs.JFIL.spare(2),'single');
refTmp = 50
refTmpIndex = 1+floor((refTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
transformationPerTemp = calcLinearTransformPerTemp(framesPerTemperature,refTmpIndex);
transformedFrames = applyTransformPerTemp(framesPerTemperature,transformationPerTemp);
[pitchTransformationPerTemp,pitchTransFrames] = calcPitchTransformPerTemp(framesPerTemperature,refTmpIndex);

% 42.1:10:62.1
% tempStages = linspace(45.1,62.1,3);
tempStages = 44:10:54;
refTmpIndices = 1+floor((tempStages-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));

plotLOSDriftByTemp(framesPerTemperature,regs,tempStages,refTmpIndices);
plotLOSDriftByTemp(transformedFrames,regs,tempStages,refTmpIndices);
plotLOSDriftByTemp(pitchTransFrames,regs,tempStages,refTmpIndices);

res(1) = calcLOSErrorByTemp(framesPerTemperature,regs,refTmpIndex);
res(2) = calcLOSErrorByTemp(transformedFrames,regs,refTmpIndex);
res(3) = calcLOSErrorByTemp(pitchTransFrames,regs,refTmpIndex);
plotLOSErrorByTemp(res,{'orig','linear fix','imported linear fix'});

plotEGeomByTemp(framesPerTemperature,regs);
plotEGeomByTemp(transformedFrames,regs);
plotEGeomByTemp(pitchTransFrames,regs);

resGeom(1) = calcAvgEGeomByTemp(framesPerTemperature,regs);
resGeom(2) = calcAvgEGeomByTemp(transformedFrames,regs);
resGeom(3) = calcAvgEGeomByTemp(pitchTransFrames,regs);
plotAvgEGeomErrByTemp(resGeom,{'orig','linear fix','imported linear fix'});


% plotRPTOverTemp(framesPerTemperature,regs,tmpBinEdges);
% plotRPTOverTemp(transformedFrames,regs,tmpBinEdges);

