function [presetCompareRes,frames] = validatePresets( hw, calibParams,runParams, fprintff)
presetCompareRes=[] ;

%% read pckr spare
hw.getFrame();
[r]=  readPckrSpare(hw);
hw.stopStream();
% set LR preset
hw.setPresetControlState(1);

if ~any(r)
    % set pckr spare
    v=single([1,1.5,1,1.5,1,1.5]);
    setPckrSpare(hw, v);
    hw.cmd('mwd a00d01f4 a00d01f8 00000fff // EXTLauxShadowUpdate');
    pause(1);
end

hw = HWinterface;
hw.startStream();
hw.getFrame(10);
LRframe=hw.getFrame(calibParams.numOfFrames);
hw.stopStream();
% set SR preset
hw.setPresetControlState(2);
hw.getFrame(10);
SRframe=hw.getFrame(calibParams.numOfFrames);
%%
frames=[]; 
frames.LRframe=LRframe; 
frames.SRframe=SRframe; 

%% diff image
diffImage=LRframe.z-SRframe.z;
presetCompareRes.meanDiff=nanmean(diffImage(:)); 
presetCompareRes.stdDiff=nanstd(diffImage(:)); 

ff = Calibration.aux.invisibleFigure();
subplot(1,2,1); imagesc(SRframe.i);colorbar; title('SR ir'); subplot(1,2,2); imagesc(LRframe.i); colorbar; title('LR ir');
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','IR_PresetsComparison',1);


ff = Calibration.aux.invisibleFigure();
imagesc(diffImage);colormap jet;colorbar;
title(sprintf(['presets comparison: LRframe.z-SRframe.z , mean diff [mm]= ' ,num2str(presetCompareRes.meanDiff)]  ));
Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','DiffZ_PresetsComparison',1);


end
%

function [r]=  readPckrSpare(hw)
startAddress='a00e1bd8';
for i=1:6
    endaddress=dec2hex(hex2dec( startAddress)+4);
    s=hw.cmd(['mrd ',startAddress,' ',endaddress]);
    s2=strsplit(s,'=> ');  s2=s2{2};
    r(i)=hex2single(s2);
    startAddress=endaddress;
end

end

function []=  setPckrSpare(hw, v)
startAddress='a00e1bd8';
for i=1:length(v)
    endaddress=dec2hex(hex2dec( startAddress)+4);
    value=single2hex(v(i));
    hw.cmd(['mwd ',startAddress,' ',endaddress ' ' value{1}]);
    startAddress=endaddress;
end

end