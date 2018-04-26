%% Create the initial configuration
% In addition run the command:  Iwb e2 03 01 1E
% So laser power will be constant and therefor tx delay is constant across the
% image.
fw = Firmware;
testregs.DEST.depthAsRange = true;
testregs.DEST.baseline = single(0);
testregs.DIGG.sphericalEn = false;
testregs.JFIL.bypass = true;
testregs.JFIL.bypassIr2Conf = true;
regsnames = 'depthAsRange|baseline|sphericalEn|JFILbypass|JFILbypassIr2Conf';
fw.setRegs(testregs,'');
fw.get();
recordDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\source\algo_ivcam2\scripts\calibScripts\RXCalib\unit79RXRecords';
fw.genMWDcmd(regsnames,fullfile(recordDir,'init4rx.txt'));

%% Collect images
hw=HWinterface();
hw.runPresetScript('startStream');
hw.runScript(fullfile(recordDir,'init4rx.txt'));
hw.shadowUpdate();



%%
for di = 1:6
   fprintf('capturing test scene at 40cm. [%d/%d] ',di,6);
   fprintf('Press any key to get the capture...\n');
   pause
   darr(di,1) = readAvgFrame(hw,75); 
   darr(di,2) = readAvgFrame(hw,75); 
   imagesc(darr(di,1).i);
end
save(fullfile(recordDir,'darr4.mat'), 'darr');

for di = 1:36
   fprintf('capturing test scene at 50cm. [%d/%d] ',di,36);
   fprintf('Press any key to get the capture...\n');
   pause
   darr50(di) = readAvgFrame(hw,15); 
   imagesc(darr50(di).c);
end
save(fullfile(recordDir,'darr.mat'),'darr40','darr50'); 

for i = 1:36
   tabplot; imagesc(darr40(i).i); 
end