% This scripts:
% 1. Loads the pipe output of the Sintel data sets. 
% 2. Trains a logistic regression classifier.
% 3. Prints the regs configuration for the conf_block
clear
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\source\IVCAM\Algo\LIDAR'))
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\source\IVCAM\Algo\Common'))

%% 1. Loads the data and prepare it for the classifer
% script hyperparams
filterDistantPixels = false; % Filters pixels with gt dist above 3500.
pipeOutPath = 'X:\Users\tmund\pipeOut100.mat';
% Load processed sintel data
load(pipeOutPath)
% concat all the relevant paramters from processed frames into a dataMat
n_pixels = numel(results(1).gt.zImg); % number of pixels in image
dataMat = zeros(length(results)*n_pixels,6);
for i=1:length(results)
    depth_gt = single(results(i).gt.zImg);
    depth_pipe = single(results(i).zImgRAW/8);
    
    IR = floor(single(results(i).iImgRAW)/2^6);
    dutyCycle = 4*single(results(i).dutyCycle);
    psnr = single(results(i).psnr);
    maxVal = single(results(i).max_val);
    
    dataMat(1+(i-1)*n_pixels:i*n_pixels,:) = [psnr(:),maxVal(:),dutyCycle(:),IR(:),depth_pipe(:),depth_gt(:)];
end
% Filter pixels with depth above 3500mmmax
filterDistantPixels = false;
if filterDistantPixels
    dataMat = dataMat(dataMat(:,6)<3500,:);
end
% Filter pixels with ir == 0 (invalid)
dataMat = dataMat(dataMat(:,4)>0,:);
% Insert conf column
final_conf = double(abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6)) <= 0.01);
% Prepare the classifier data
trainDat = dataMat(:,2:4);

depthError = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6));
%% Train the logistic regression classifier
W = glmfit(trainDat,final_conf,'binomial');
%% Plot the ROC curve:
% Scale the weights to use as much of the valid range [-128,17]
W_max = max(abs(W(2:4)));
W_final = cast(W(2:4)*127/W_max,'int16');

inputDat = cast(dataMat(:,2:4),'int16');
getLogits = @(X)  double(X)*double(W_final);
logits = cast(getLogits(inputDat),'int16');

% In the conf block, the multiplication results is mapped to the range [-128.127]. Let us do it:
posW = W_final(W_final>0);
negW = W_final(W_final<0);
minActIn1 = sum(negW*63);
maxActIn1 = sum(posW*63);
dtAct1 = int16(maxActIn1-minActIn1);
x0Act1 = int16(minActIn1);
actOut1 = int8(((int32(logits)-int32(x0Act1))*255)/int32(dtAct1)-128);

% Now we shall pass the last activation that will map the logits from [-128,127] to [0,255]:
minActIn2 = -128;
maxActIn2 = 127;
dtAct2 = int16(maxActIn2-minActIn2);
x0Act2 = int16(minActIn2);
actOut2 = uint8(((int32(actOut1)-int32(x0Act2))*255)/int32(dtAct2));

% Now we apply bit shift 4 and take max(in,1):
final_conf = idivide(actOut2,2^4,'floor');


%% Let us plot the True Positive / True Negative rate:
plotClassificationRatesCurve = true;
if plotClassificationRatesCurve
    th = 0:0.5:15;
    labels = depthError <=0.01;
    true_pos_rate = zeros(size(th));
    true_neg_rate = zeros(size(th));
    for i = 1:numel(th)
        true_pos_rate(i) = sum((final_conf>th(i)) .* labels) ./ sum(labels);
        true_neg_rate(i) = sum((final_conf<=th(i)) .* (1-labels)) ./ sum(1-labels);
    end
    figure
    subplot(1,2,1)
    mean_rate = mean([true_pos_rate;true_neg_rate]);
    plot(th,mean_rate); xlabel('threshold');ylabel('mean rates');title('average between TPR and TNR');
    [maxv,I] = max(mean_rate);
    txt = strcat('\leftarrow', sprintf('(TNR,TPR)=(%.2f,%.2f)',true_neg_rate(I),true_pos_rate(I)));
    text(th(I),mean_rate(I),txt)
    hold on
    plot(th(I),mean_rate(I),'r*')
    t = th(I);
    subplot(1,2,2)
    plot(true_neg_rate,true_pos_rate); xlabel('true neg rate');ylabel('true pos rate');title('TPR,TNR by changing lambda');
    AUC = sum( true_pos_rate.*(true_neg_rate-[0,true_neg_rate(1:end-1)]));
    text(0.2,0.2,sprintf('AUC=%.3f',AUC))
    hold on
    plot(true_neg_rate(I),true_pos_rate(I),'r*')
    txt = strcat('\leftarrow', sprintf('(%.2f,%.2f)',true_neg_rate(I),true_pos_rate(I)));
    text(true_neg_rate(I),true_pos_rate(I),txt)
end
%% Determine the reg values (Copy the resulting values)
regs.DEST.confIRbitshift = uint8(6); % confIRbitshift determines which 6 bits to use from the IR value (12b -> 6b)
regs.DEST.confw1 = [int8(W_final(2)),int8(0),int8(W_final(1)),int8(W_final(3))]; % Calculated scaled weights value. [dutyCycle,psnr,maxVal,IR].
regs.DEST.confw2 = [int8(0),int8(0),int8(0),int8(0)]; % Other weights path should be ignored.
regs.DEST.confv = [int8(0),int8(0),int8(0),int8(0)]; % All biases are zero.
regs.DEST.confq = [int8(1),int8(0)];% Keep the first channel. Zero the second.
dt = int16(maxActIn2); x0 = int16(-minActIn1); % Activation maps [minPrev,maxPrev]->[-128,127]. dt and x0 are calculated as dtAct1,xoAct1
regs.DEST.confactIn = [x0,dt];
dt = int16(255); x0 = int16(-128);% Activation maps [-128,127]->[0,255]. dt and x0 are calculated as dtAct2,xoAct2
regs.DEST.confactOt = [x0,dt];

