%% Create the initial configuration
% In addition run the command:  Iwb e2 03 01 1E
% So laser power will be constant and therefor tx delay is constant across the
% image.
initDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\RXCalib\initScript';
fw = Pipe.loadFirmware(initDir);
testregs.DEST.depthAsRange = true;
testregs.DIGG.sphericalEn = true;
testregs.JFIL.invConfThr = uint8(0);
testregs.JFIL.bypass = true;
testregs.JFIL.bypassIr2Conf = true;
configfn = fullfile(initDir,'config.csv');
fw.setRegs(testregs,configfn);
fw.get();
fw.writeUpdated(configfn);
fw.genMWDcmd([],fullfile(initDir,'initScriptRXDelay.txt'));

%% Collect images
hw=HWinterface(fw);
recordDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\RXCalib\collectedDataAvg300';


%%
for di = 1:18
   fprintf('capturing test scene at 40cm. [%d/%d] ',di,36);
   fprintf('Press any key to get the capture...\n');
   pause
   darr40(di,1) = readAvgFrame(hw,600); 
   darr40(di,2) = readAvgFrame(hw,600); 
   imagesc(darr40(di,1).i);
end
save(fullfile(recordDir,'darr.mat'), 'darr40');

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