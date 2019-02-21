[frames,coolingStage] = loadDataSet();
hw = HWinterface;
roiRegs = readRoiRegs(hw);
fw = Pipe.loadFirmware(fwPath);
fw.setRegs(roiRegs,'');
regs = fw.get();
%% plot temperature over time
plotTemperature(frames,coolingStage);

%% plot rtd,angx,angy over time
plotEGeom(frames,coolingStage,regs);

%% Show Los Error
% Group frames for each ldd temperature - compute los metric. Once for all,
% and one is the mean for each trial seperately.
tmpBinEdges = 25:0.5:70;
framesPerTemperature = groupFramesByTemp(frames,25:0.5:70,'ldd');
transformationPerTemp = calcLinearTransformPerTemp(framesPerTemperature,tmpBinEdges,refTmpInd);
