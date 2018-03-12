%% Create the FW used for recording
initDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibFromDataset\initScriptWithR';
fw = Pipe.loadFirmware(initDir);
testregs.DEST.depthAsRange = true;
testregs.JFIL.invConfThr = uint8(0);

configfn = fullfile(initDir,'config.csv');
fw.setRegs(testregs,configfn);
fw.get();
fw.writeUpdated(configfn);
fw.genMWDcmd([],fullfile(initDir,'initScriptDepthAsRange.txt'));

%% Prepare for recording:
hw=HWinterface(fw);
recordDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibFromDataset\recordedData';
baseName = 'largeCB';%'regularCB'; % Large CB has 4.8824cm squares
i=0;
%% Record an Image with ctrl+enter:
if i < 24
    d = Calibration.aux.readAvgFrame(hw,30);
    fname = fullfile(recordDir,strcat(baseName,'_',num2str(i,'%0.2d'),'.mat'));
    save(fname,'d');
    i = i+1
    imagesc(d.i)
else
    fprintf('Done.');
end

%% Show the recordings:
for i = 0:24
    fname = fullfile(recordDir,strcat(baseName,'_',num2str(i,'%0.2d'),'.mat'));
    rec = load(fname);
    tabplot;
    imagesc(rec.d.i)
end