dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_latest';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_third_trial';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0021_Regular_24_2_num_2';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0093_25_2_num_3';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0093_26_2';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0093_26_2_with_thermal_loop';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0077_26_2';
dataSetDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0077_27_2_with_fw_loop';
ignoreFirstNDeg = 2;
[frames,coolingStage] = loadDataSet(dataSetDir,ignoreFirstNDeg);
regsPath = fullfile(dataSetDir,'regs.mat');
regs = load(regsPath); regs = regs.regs;
% regs.DEST.tmptrOffset = -27.5536;
regs.DEST.tmptrOffset = 0;

%% plot temperature over time
plotTemperature(frames,coolingStage);

%% plot rtd,angx,angy over time
plotEGeom(frames,coolingStage,regs);

%% Show Los Error
% Group frames for each ldd temperature - compute los metric. Once for all,
% and one is the mean for each trial seperately.
tmpBinEdges = (25:0.5:70) - 0.25;
framesPerTemperature = groupFramesByTemp(frames,tmpBinEdges,'ldd');
refTmp = typecast(regs.JFIL.spare(2),'single');
% refTmp = 50
refTmpIndex = 1+floor((refTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
transformationPerTemp = calcLinearTransformPerTemp(framesPerTemperature,refTmpIndex);
transformedFrames = applyTransformPerTemp(framesPerTemperature,transformationPerTemp);
[pitchTransformationPerTemp,pitchTransFrames] = calcPitchTransformPerTemp(framesPerTemperature,refTmpIndex);

% 42.1:10:62.1
% tempStages = linspace(45.1,62.1,3);
tempStages = [46.5,53];
tempStages = 50:10:60;
refTmpIndices = 1+floor((tempStages-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));

plotLOSDriftByTemp(framesPerTemperature,regs,tempStages,refTmpIndices);
plotLOSDriftByTemp(transformedFrames,regs,tempStages,refTmpIndices);
plotLOSDriftByTemp(pitchTransFrames,regs,tempStages,refTmpIndices);

res(1) = calcLOSErrorByTemp(framesPerTemperature,regs,refTmpIndex);
res(2) = calcLOSErrorByTemp(transformedFrames,regs,refTmpIndex);
res(3) = calcLOSErrorByTemp(pitchTransFrames,regs,refTmpIndex);
plotLOSErrorByTemp(res,{'orig','linear fix','fw fix'});

plotEGeomByTemp(framesPerTemperature,regs);
plotEGeomByTemp(transformedFrames,regs);
plotEGeomByTemp(pitchTransFrames,regs);

resGeom(1) = calcAvgEGeomByTemp(framesPerTemperature,regs);
resGeom(2) = calcAvgEGeomByTemp(transformedFrames,regs);
resGeom(3) = calcAvgEGeomByTemp(pitchTransFrames,regs);
plotAvgEGeomErrByTemp(resGeom,{'orig','linear fix','fw fix'});


showCycleConsistency(frames,tmpBinEdges,regs,refTmp,refTmpIndex);


% plotRPTOverTemp(framesPerTemperature,regs,tmpBinEdges);
% plotRPTOverTemp(transformedFrames,regs,tmpBinEdges);

%% Create fix table:

fixTable = calcFixTable(transformationPerTemp,tmpBinEdges,regs);
figure,
titles = {'dsmXscale','dsmYscale','dsmXoffset','dsmYoffset','RTD Offset'};
xlabels = 'Ldd Temperature [degrees]';
for i = 1:5
    tabplot;
    plot((25:0.5:70.5),fixTable(:,i));
    title(titles{i});
    xlabel(xlabels);
end
resultDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\F9010077_8_view';
saveThermalTable(fixTable , fullfile(resultDir,'FlashRw_PI_Dynamic_Configuration_QVGA_Ver_0_0.bin'));


hw.cmd('WriteFullTable X:\Data\IvCam2\temperaturesData\results\0077_26_2\FlashRw_PI_Dynamic_Configuration_QVGA_Ver_2_1.bin');