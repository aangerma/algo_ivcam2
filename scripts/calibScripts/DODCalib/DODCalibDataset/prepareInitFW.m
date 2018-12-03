%% Create the FW used for recording
initDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\initConfigCalibVer2';
fw = Pipe.loadFirmware(initDir);
testregs.DEST.depthAsRange = true;
testregs.DIGG.sphericalEn = true;
testregs.JFIL.invConfThr = uint8(0);

configfn = fullfile(initDir,'config.csv');
fw.setRegs(testregs,configfn);
fw.get();
fw.writeUpdated(configfn);
fw.genMWDcmd([],fullfile(initDir,'initConfigCalibDepthAsRange.txt'));

%% Prepare for recording:
hw=HWinterface(fw);
recordDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedDataVer2';
baseName = 'largeWithregularCB';%'regularCB'; % Large CB has 4.8824cm squares
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



%% Records #3 
%{ 
For each distance 40,50,60 c"m take:
 1. 5 captures when the board is perpendicular to the camera. 
 2. 5 captures when the board is slightly tilted to one side (~10deg).
 3. 5 captures when the board is slightly tilted to the other side (~10deg).
In addition, take 5 test images where the target is around 1 meter.
%}

hw=HWinterface(fw);
recordDir = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedDataVer3';


dists = [40,50,60];
angs = {'';'_-10';'_+10'};

for j = 1:numel(dists)
    for a = 1:numel(angs)
        if j == 1 && a == 1 
            continue;
        end
        dirname = fullfile(recordDir,strcat('d',num2str(dists(j)),angs{a}));
        status = mkdir(dirname);
        clear 'darr'
        for di = 1:5
           fprintf('capturing scene. Next captures is at: dist=%d, ang = %s.\n',dists(j),angs{a})
           fprintf('Press any key to get the next capture...\n');
           pause
           darr(di) = Calibration.aux.readAvgFrame(hw,30); 
           tabplot; imagesc(darr(di).i);tabplot; imagesc(darr(di).z);
           
           
           
        end
        dpath = fullfile(dirname,'darr.mat');
        save(dpath,'darr');
    end
end

%%
for di = 1:10
   fprintf('capturing test scene. [%d/%d] ',di,10);
   fprintf('Press any key to get the capture...\n');
   pause
   darr(di) = Calibration.aux.readAvgFrame(hw,30); 
   tabplot; imagesc(darr(di).z);tabplot; imagesc(darr(di).i);
end
save 'darr.mat' 'darr'

