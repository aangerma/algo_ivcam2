hw = HWinterface;
[~,unitName,~] = hw.getInfo();
calibParams = xml2structWrapper('calibParams.xml');
runParams.outputFolder = unitName;
mkdirSafe(runParams.outputFolder);
% Every minute take 30 frames and calculate interdist
N = 30;
hw.getFrame(50);
for i = 1:100
   frames = hw.getFrame(N);
   [ dfzRes,allRes,dbg ] = Calibration.validation.validateDFZ( hw,frames,@fprintf,calibParams,runParams);
   eGeom(i) = dfzRes.GeometricError;
   [ lddTmptr(i),tSense(i),vSense(i),tmpPvt(i) ] = Calibration.aux.collectTempData(hw,runParams,sprintf('eGeomVal, %2.2f',eGeom(i)));
   
   hw.cmd('rst');
   pause(3);
   hw = HWinterface;
   hw.getFrame(50);
end

savePath = fullfile(runParams.outputFolder,'data.mat');
save(savePath,'eGeom','lddTmptr','tSense','vSense','tmpPvt')