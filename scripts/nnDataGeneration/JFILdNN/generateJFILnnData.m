% Take Sintel Frames and process them through throught the pipe. Save the
% Resulting data as binary files for tensorflow to read. Each binary file
% consists of the 14 features and the depth gt.
% Once done run the depth_nn script in tensorflow to train the network
% weights. It will update the weights file under X drive, and the function
% dNNRegs(regs) will update the regs using the weights of the network.

clear
N_RUNS = 1064;
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\ivcam2.0'))
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\git\AlgoCommon\Common'))
mainDir = 'X:\Data\IvCam2\NN\NNdataset\MPI-Sintel-complete\training\';
saveDirDepth = 'X:\Data\IvCam2\NN\JFIL\sintelBinFramesAugmentedDepth';
saveDirIR= 'X:\Data\IvCam2\NN\JFIL\sintelBinFramesAugmentedIR';


albdoFiles = dirRecursive(fullfile(mainDir,'albedo'),'*.png');
depthFiles = strrep(strrep(albdoFiles,fullfile(mainDir,'albedo'),fullfile(mainDir,'depth')),'.png','.dpt');
ok = cellfun(@(x) exist(x,'file')~=0,depthFiles );
albdoFiles=albdoFiles(ok);
depthFiles=depthFiles(ok);
nframes = nnz(ok);

%% REGS SET
regs.FRMW.xres = uint16(640);
regs.FRMW.yres = uint16(480);
regs.FRMW.xfov = single(72);
regs.FRMW.guardBandV = single(0);
regs.FRMW.guardBandH = single(0);
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

% Feature extraction and NN
regs.JFIL.dFeaturesConfThr = uint8(0);


% dnn regs
regs = nnRegs(regs); 
% bilateral regs
regs = btRegs(regs);

rng(12345);
ind = randperm(nframes,N_RUNS);


confNorm = single(1/15);
irNorm = single(1/(2^12-1));
nnNorm = single(1/64000);
normFactors = [confNorm;irNorm;nnNorm];
    
fn = fullfile(saveDirIR,strcat('norm_factors','.bin'));
fid = fopen(fn,'wb');
fwrite(fid,single(normFactors),'single');
fclose(fid);

fn = fullfile(saveDirDepth,strcat('norm_factors','.bin'));
fid = fopen(fn,'wb');
fwrite(fid,single(normFactors),'single');
fclose(fid);

j = 0;
while true
    %%
    i = mod(j,N_RUNS)+1;
    j = j + 1;
    
    zIm = max(0,depth_read(depthFiles{ind(i)})*1000); %mm
    aIm = mean(imread(albdoFiles{ind(i)}),3)/255; %[0 1]
    
    if mean(zIm(:)<3500) < 0.1
       continue 
    end
    
    
    
    [zIm,aIm] = augmentDepthAndAlbedo(zIm,aIm);
    
    fprintf('%2d/%2d (%04d) generating data...',i,N_RUNS,ind(i));
    [ivsFilename,gt] = Pipe.patternGenerator(regs,'zimg',zIm,'aimg',aIm);
    intensity = albedo2Intensity(regs,gt.zImg,gt.aImg);
    fprintf('running pipe...');
    pout = Pipe.autopipe(ivsFilename,'verbose',0,'viewResults',0,'saveresults',0);
    pout.gt=gt;
    pout.frameNum = ind(i);

    % Depth Data
    features_single = Utils.fp20('to',pout.nnfeatures.d(:,:,1:14));
    dataMatDepth = cat(3,single(pout.gt.zImg),features_single);
    dataMatDepth = permute(dataMatDepth,[3 2 1]);
    if ~isempty(dataMatDepth)
        % save current frame in a binary format
        fn = fullfile(saveDirDepth,strcat('frame_',num2str(j),'.bin'));
        fid = fopen(fn,'wb');
        fwrite(fid,single(vec(dataMatDepth)),'single');
        fclose(fid);
        fprintf('Bin Depth frame %d done. ',j);
    end
    % IR Data
    features_single = Utils.fp20('to',pout.nnfeatures.i(:,:,1:12));
    dataMatIR = cat(3,single(pout.gt.zImg),single(intensity),features_single);
    dataMatIR = permute(dataMatIR,[3 2 1]);
    if ~isempty(dataMatIR)
        % save current frame in a binary format
        fn = fullfile(saveDirIR,strcat('frame_',num2str(j),'.bin'));
        fid = fopen(fn,'wb');
        fwrite(fid,single(vec(dataMatIR)),'single');
        fclose(fid);
        fprintf('Bin IR frame %d done\n',j);
    end    
end




