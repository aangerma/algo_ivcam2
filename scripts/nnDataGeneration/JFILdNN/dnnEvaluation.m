% This script evaluates some error metrics on three depth images:
% 1. The depth image at the enterance the dNN.
% 2. The depth image at the output of the dNN.
% 3. The depth image after applying the dnn with floating point operations (as was trained in tensorflow).
% The error criteria are:
% 1. Mean depth relative error for close pixels.
% 2. Mean depth relative error for pixels with initial RE below 10%.

clear
N_IMAGES = 1;
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\ivcam2.0'))
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\AlgoCommon\Common'))
mainDir = 'X:\Data\IvCam2\NN\NNdataset\MPI-Sintel-complete\training\';
%
albdoFiles =dirRecursive(fullfile(mainDir,'albedo'),'*.png');
depthFiles = strrep(strrep(albdoFiles,fullfile(mainDir,'albedo'),fullfile(mainDir,'depth')),'.png','.dpt');
ok = cellfun(@(x) exist(x,'file')~=0,depthFiles );
albdoFiles=albdoFiles(ok);
depthFiles=depthFiles(ok);
nframes = nnz(ok);
% REGS SET
regs.FRMW.xres = uint16(640);
regs.FRMW.yres = uint16(480);
regs.FRMW.xfov = single(72);
regs.FRMW.gaurdBandV = single(0);
regs.FRMW.gaurdBandH = single(0);
regs.FRMW.yfov = single(52);
regs.JFIL.dnnBypass = false;
regs.JFIL.innBypass = false;
regs.EPTG.frameRate = single(60);
regs.DIGG.notchBypass = true; % no notch filter
regs.DIGG.gammaBypass = true; % no gamma filter
regs.DEST.baseline=single(30);

% Confidence Regs
regs.DEST.confIRbitshift = uint8(6); % confIRbitshift determines which 6 bits to use from the 
regs.DEST.confw1 = [int8(30),int8(0),int8(127),int8(-56)]; % Calculated scaled weights value. 
regs.DEST.confw2 = [int8(0),int8(0),int8(0),int8(0)]; % Other weights path should be ignored.
regs.DEST.confv = [int8(0),int8(0),int8(0),int8(0)]; % All biases are zero.
regs.DEST.confq = [int8(1),int8(0)];% Keep the first channel. Zero the second.
dt = int16(13419); x0 = int16(-3528); % Activation maps [minPrev,maxPrev]->[-128,127]. dt and 
regs.DEST.confactIn = [x0,dt];
dt = int16(255); x0 = int16(-128);% Activation maps [-128,127]->[0,255]. dt and x0 are calculated 
regs.DEST.confactOt = [x0,dt];
regs = nnRegs(regs);
regs = btRegs(regs);

rng(12345);
ind = randperm(nframes,N_IMAGES+100);
% Prepare the data
results=[];
for i= 1:N_IMAGES
    i = 42
    zIm = max(0,depth_read(depthFiles{ind(i)})*1000); %mm
    aIm = mean(imread(albdoFiles{ind(i)}),3)/255; %[0 1]
    
    fprintf('%2d/%2d (%04d) generating data...',i,N_IMAGES,ind(i));
    [ivsFilename,gt] = Pipe.patternGenerator(regs,'zimg',zIm,'aimg',aIm);
    fprintf('running pipe...');
    pout = Pipe.autopipe(ivsFilename,'verbose',0,'viewResults',0,'saveresults',0);
    pout.gt=gt;
    pout.frameNum = ind(i);
    results=[results pout ];
    fprintf('done\n');
end
% save('X:\Data\IvCam2\NN\pipeOut.mat','results','-v7.3');    

%% Evaluate it
% load('X:\Users\tmund\New folder\pipeOut.mat');    
fp20Error = zeros(N_IMAGES,480,640);
valid = zeros(N_IMAGES,480,640);
nnNorm = single(1/64000);
reTh = 0.1;
mdreClose = zeros(N_IMAGES,3);
mdreHopeful = zeros(N_IMAGES,3);
confWeights = false;
for i=1:N_IMAGES
    gtDepth = single(results(i).gt.zImg);
    conf = ones(size(results(i).cImg));
    if confWeights
        conf = single(results(i).cImg);
    end
    netInputDepth =  Utils.fp20('to',results(i).nnfeatures.d(:,:,1))/nnNorm;
    netOutputDepth = results(i).dNNOutput;
    netOutputExpected = dnnExact(Utils.fp20('to',results(i).nnfeatures.d));
    
    fp20Error(i,:,:) = abs(netOutputExpected - single(netOutputDepth))/8; 
    valid(i,:,:) = gtDepth<3500; 
    
    closeMask = gtDepth < 3500;
    initRe = abs(gtDepth-netInputDepth/8)./(gtDepth+1e-6);
    
    hopefulMask = closeMask & (initRe < reTh);
    if sum(closeMask(:))<10000
       continue 
    end
    
    outRe = abs(gtDepth-single(netOutputDepth)/8)./(gtDepth+1e-6);
    expectedOutRe = abs(gtDepth-netOutputExpected/8)./(gtDepth+1e-6);
    
    
    
    
    
    mdreClose(i,1) = mean(initRe(closeMask).*conf(closeMask));
    mdreClose(i,2) = mean(outRe(closeMask).*conf(closeMask));
    mdreClose(i,3) = mean(expectedOutRe(closeMask).*conf(closeMask));
    
    mdreHopeful(i,1) = mean(initRe(hopefulMask).*conf(hopefulMask));
    mdreHopeful(i,2) = mean(outRe(hopefulMask).*conf(hopefulMask));
    mdreHopeful(i,3) = mean(expectedOutRe(hopefulMask).*conf(hopefulMask));
    
end
valid = logical(valid);
% Plot error histogram
figure
subplot(1,2,1)
histogram(fp20Error(valid),1000,'normalization','cdf')
ttl = strcat('\mu = ',sprintf('%.2fmm',mean(fp20Error(valid))),', \sigma = ',sprintf('%.2fmm',std(fp20Error(valid))));
title({'Depth Comulative Histogram - Close Pixels';ttl})
subplot(1,2,2)
histogram(fp20Error(:),1000,'normalization','cdf')
ttl = strcat('\mu = ',sprintf('%.2fmm',mean(fp20Error(:))),', \sigma = ',sprintf('%.2fmm',std(fp20Error(:))));
title({'Depth Comulative Histogram - All Pixels';ttl})
% Plot results
figure
subplot(2,2,1)
stem(mdreClose)
legend('init','dnnOut','dnnOutExact')
title('mdreClose (Per Image)')
subplot(2,2,2)
stem(mdreHopeful)
legend('init','dnnOut','dnnOutExact')
title('mdreHopeful (Per Image)')
subplot(2,2,3)
bar(mean(mdreClose)')
set(gca, 'XTickLabel', {'init','dnnOut','dnnOutExact'})
title('mdreClose')
subplot(2,2,4)
bar(mean(mdreHopeful)')
set(gca, 'XTickLabel', {'init','dnnOut','dnnOutExact'})
title('mdreHopeful')

%% Evaluate on the binary files (Only the exact net - not the pipe)
data_dir = 'X:\Data\IvCam2\NN\JFIL\SintelBinFramesMany';

N_IMAGES = 2;
nnNorm = single(1/64000);
reTh = 0.1;
mdreClose = zeros(N_IMAGES,2);
mdreHopeful = zeros(N_IMAGES,2);
confWeights = true;

exactOut = zeros(480,640,N_IMAGES);

for i=1:N_IMAGES

    fileID = fopen(fullfile(data_dir,strcat('frame_',num2str(i),'.bin')));
    features = fread(fileID,'single');
    features = reshape(features,[15,640,480]);
    features = permute(features,[3 2 1]);
     
    gtDepth = features(:,:,1);
    conf = ones(size(features(:,:,3)));
    if confWeights
        conf = features(:,:,3);
    end
    netInputDepth =  features(:,:,2)/nnNorm;
    netOutputExpected = dnnExact(features(:,:,2:15));
    
    closeMask = gtDepth < 3500;
    initRe = abs(gtDepth-netInputDepth/8)./(gtDepth+1e-6);
    
    hopefulMask = closeMask & (initRe < reTh);
    if sum(closeMask(:))<10000
       continue 
    end
    
    expectedOutRe = abs(gtDepth-netOutputExpected/8)./(gtDepth+1e-6);
    
    
    
    
    
    mdreClose(i,1) = mean(initRe(closeMask).*conf(closeMask));
    mdreClose(i,2) = mean(expectedOutRe(closeMask).*conf(closeMask));
    
    mdreHopeful(i,1) = mean(initRe(hopefulMask).*conf(hopefulMask));
    mdreHopeful(i,2) = mean(expectedOutRe(hopefulMask).*conf(hopefulMask));
    
end
% Plot results
figure
subplot(2,2,1)
stem(mdreClose)
legend('init','dnnOutExact')
title('mdreClose (Per Image)')
subplot(2,2,2)
stem(mdreHopeful)
legend('init','dnnOutExact')
title('mdreHopeful (Per Image)')
subplot(2,2,3)
bar(mean(mdreClose)')
set(gca, 'XTickLabel', {'init','dnnOutExact'})
title('mdreClose')
subplot(2,2,4)
bar(mean(mdreHopeful)')
set(gca, 'XTickLabel', {'init','dnnOutExact'})
title('mdreHopeful')

%%
afterNet = netOutputExpected/8;
afterNet(gtDepth>3500) = 3500;
gtDepth(gtDepth>3500) = 3500;
az = 10;
el = -85;
subplot(1,2,1)
mesh(gtDepth)
view(az, el);
subplot(1,2,2)
mesh(afterNet)
view(az, el);

%%
beforeNet = single(netInputDepth)/8;
afterNet = netOutputExpected/8;
afterNet(gtDepth>3500) = 3500;
gtDepth(gtDepth>3500) = 3500;
beforeNet(gtDepth>3500) = 3500;

GTVals = gtDepth(:);
[r,c] = find(ones(480,640));

GT = [r,c,GTVals];
DOUT = [r,c,afterNet(:)];
DIN = [r,c,beforeNet(:)];

subplot(1,3,1)
pcshow(DIN)
title('Before NN')
axis([0 480 0 640 0 3500])
subplot(1,3,2)
pcshow(DOUT)
title('After NN')
axis([0 480 0 640 0 3500])
subplot(1,3,3)
pcshow(GT)
title('GT')
axis([0 480 0 640 0 3500])