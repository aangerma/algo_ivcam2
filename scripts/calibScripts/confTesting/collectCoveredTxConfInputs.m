hw = HWinterface();
names = {'dc';'psnr';'max peak';'ir'};
inputs = zeros(480,640,4);
hw.getFrame(30);

%% Collect confidence
% r=Calibration.RegState(hw);
% r.add('JFILbypass$'        ,true    );+
% r.set();
hw.cmd('mwd a00e0f00 a00e0f04 00000001 // JFILbypass');
hw.runScript('binaryTrainedConf.txt');
hw.shadowUpdate();
conf = hw.getFrame(30).c;


% r=Calibration.RegState(hw);
% r.add('JFILbypass$'        ,true    );
% r.set();
% confbin = hw.getFrame(30).c;
% r.reset();


%% Collect Inputs
for i = 1:4
    inputs(:,:,i) = readConfInput(hw,1,i)*4;
    tabplot;
    imagesc(inputs(:,:,i),[0,63]); colorbar;
    title(names{i});
end

% inputs(inputs == 4) = 0;
% inputs(:,:,[1,3,4]) = inputs(:,:,[1,3,4])+ (randi(4,[480,640,3])-1);

fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
regs = fw.get();
confOut = Pipe.DEST.confBlock( inputs(:,:,1)/4, inputs(:,:,2), inputs(:,:,3),double(int32(inputs(:,:,4)*2^6)),  regs );

hw.runScript('binaryTrainedConf.txt');
hw.shadowUpdate();
conf = hw.getFrame(1).c; 
% tabplot;
% imagesc(confbin,[0,15]); colorbar;
% title('ConfBin');
tabplot;
imagesc(conf,[0,15]); colorbar;
title('initConf');

tabplot;
imagesc(confOut,[0,15]); colorbar;
title('expectedConf');

% r.reset();
hw.runScript('binaryTrainedConfModifiedToRemoveMaxPeak0.txt');
hw.shadowUpdate();
confNew = hw.getFrame(30).c;
tabplot;
imagesc(confNew,[0,15]); colorbar;
title('newConf');



invalidConf = isnan(prod(inputs,3));
figure,imagesc(invalidConf)