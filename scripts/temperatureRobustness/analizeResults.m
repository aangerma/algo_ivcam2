dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_latest';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0021';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_bad_regs - Copy';
[frames,coolingStage] = loadDataSet(dataSetDir);
regsPath = fullfile(dataSetDir,'regs.mat');
regs = load(regsPath); regs = regs.regs;
regs.DEST.tmptrOffset = -27.5536;
%% plot temperature over time
plotTemperature(frames,coolingStage);

%% plot rtd,angx,angy over time
plotEGeom(frames,coolingStage,regs);

%% Show Los Error
% Group frames for each ldd temperature - compute los metric. Once for all,
% and one is the mean for each trial seperately.
tmpBinEdges = 25:0.5:70;
framesPerTemperature = groupFramesByTemp(frames,25:0.5:70,'ldd');
refTmp = typecast(regs.JFIL.spare(2),'single');
refTmpIndex = 1+floor((refTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
transformationPerTemp = calcLinearTransformPerTemp(framesPerTemperature,refTmpIndex);
transformedFrames = applyTransformPerTemp(framesPerTemperature,transformationPerTemp);
plotEGeomByTemp(framesPerTemperature,regs);
plotEGeomByTemp(transformedFrames,regs);


tempStages = 42.1:10:62.1;
refTmpIndices = 1+floor((tempStages-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));

plotLOSByTemp(framesPerTemperature,regs,tempStages,refTmpIndices);
plotLOSByTemp(transformedFrames,regs,tempStages,refTmpIndices);

plotRPTOverTemp(framesPerTemperature,regs,tmpBinEdges);
plotRPTOverTemp(transformedFrames,regs,tmpBinEdges);