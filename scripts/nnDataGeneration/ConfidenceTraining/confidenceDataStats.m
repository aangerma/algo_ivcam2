%%
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\source\IVCAM\Algo\LIDAR'))
addpath(genpath('\\tmund-MOBL1.ger.corp.intel.com\c$\source\IVCAM\Algo\Common'))

%% Load processed sintel data
load('X:\Users\tmund\pipeOut100.mat')
%% script hyperparams
filter_distant_pixels = false; % Filters pixels with gt dist above 3500.
%% concat all the relevant paramters from processed frames into a dataMat
n_pixels = numel(results(1).gt.zImg); % number of pixels in image
dataMat = zeros(length(results)*n_pixels,6);
for i=1:length(results)
    
    depth_gt = single(results(i).gt.zImg);
    depth_pipe = single(results(i).zImgRAW/8);
    
    IR = single(results(i).iImgRAW);
    dutyCycle = single(results(i).dutyCycle);
    psnr = single(results(i).psnr);
    maxVal = single(results(i).max_val);
    
    dataMat(1+(i-1)*n_pixels:i*n_pixels,:) = [psnr(:),maxVal(:),dutyCycle(:),IR(:),depth_pipe(:),depth_gt(:)];

end

% Filter pixels with depth above 3500mmmax
if filter_distant_pixels
    dataMat = dataMat(dataMat(:,6)<3500,:);
end
% Filter pixels with ir == 0 (invalid)
dataMat = dataMat(dataMat(:,4)>0,:);

%% Insert conf column
conf = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6)) <= 0.01;


%% analize dataset stats
posDataMat = dataMat(conf,:);
negDataMat = dataMat(~conf,:);
paramNames = {'psnr','maxVal','dutyCycle','IR'};
n_pos = size(posDataMat,1);
n_neg = size(negDataMat,1);
n_max = max([n_pos,n_neg]);
for i = 1:4
    % interpolate values in neg to have the same number of values
    pos_i = sort(posDataMat(:,i));
    neg_i = sort(negDataMat(:,i));
    range_neg = linspace(1, n_neg, n_max);
    range_pos = linspace(1, n_pos, n_max);
    pos_i = interp1(1:n_pos, pos_i, range_pos);
    neg_i = interp1(1:n_neg, neg_i, range_neg);
    
    subplot(4,1,i)
    plot(pos_i,'g-','LineWidth',2)
    hold on 
    plot(neg_i,'r-','LineWidth',2)
    legend('Pos','Neg')
    title_str = sprintf('Sorted %s',paramNames{i});
    title(title_str)
end

%% view depth error with respect to each param
depthError = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6));
for i = 1:4
    [paramSorted,I] = sort(dataMat(:,i));
    errorsI = depthError(I);
    n_quant = min([100,max(paramSorted)-min(paramSorted)]);
    
    quant = linspace(min(paramSorted),max(paramSorted),n_quant+1);
    pos_percent_per_val = zeros(n_quant,1); 
    mean_error_per_val = zeros(n_quant,1); 
    for m = 1:n_quant
        mean_error_per_val(m) = mean(errorsI(logical((paramSorted >= quant(m)).*(paramSorted < quant(m+1) ))  ));
        pos_percent_per_val(m) = mean(errorsI(logical((paramSorted >= quant(m)).*(paramSorted < quant(m+1) )))>0.01);
    end
    subplot(4,1,i)
    plot(quant(1:end-1),mean_error_per_val,'LineWidth',1.5)
    hold on 
    plot( quant(1:end-1),pos_percent_per_val,'LineWidth',1.5)
    legend('Mean Dist Err','Above 1% Rate')
    hold on 
    plot(quant(1:end-1),0.01*ones(1,n_quant),'g' )
    xlabel(paramNames{i})
    title('Dist Relative Error and Error Rate per Param Value')
end


%% Look at specific frames, show a map of maxval
f = 11;
depth_gt = results(f).gt.zImg;
depth_pipe = double(results(f).zImgRAW)/8;
distRE = abs(depth_gt-depth_pipe)./depth_gt;
conf = distRE <= 0.01;
IR = results(f).iImgRAW;
dutyCycle = results(f).dutyCycle;
psnr = results(f).psnr;
maxVal = results(f).max_val;

distREPerMaxMaxVal = distRE(maxVal== max(maxVal(:)));

subplot(321)
depth_gt(depth_gt>10000) = 0;
imagescNAN(depth_gt);title('depth(GT)')
colorbar
subplot(322)
[minz,maxz] = minmax(depth_gt(:));
imagescNAN(depth_pipe,[minz,maxz]);title('depth(Pipe)')
colorbar
subplot(323)
imagescNAN(maxVal== max(maxVal(:)));title('maximal maxVal(Pipe)')
colorbar
subplot(324)
imagesc(conf);title('Confidence(GT)')
colorbar
subplot(325)
imagesc(IR);title('intensity(Pipe)')
colorbar
subplot(326)
histogram(distREPerMaxMaxVal,linspace(0,0.1,50),'Normalization','cdf');title('Relative Dist Error for Max Valued pixels CDF')
fprintf('done\n');
drawnow;

maximalValGood = sum((maxVal(:) == max(maxVal(:))).*(conf(:))) /sum((maxVal(:) == max(maxVal(:))))

%% Show histogram of relative depth error with respect to saturated max_val pixels
depthError = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6));
maxVal = dataMat(:,2);
depthErrorStMaxVal = depthError(maxVal == max(maxVal(:)));
histogram(distREPerMaxMaxVal,linspace(0,0.1,50),'Normalization','cdf');title('Relative Dist Error for Max Valued pixels CDF')

%% train SVM on each data configuration
% Train on a subset of positive and negative samples.
table = dec2bin(1:(2^3-1)) - '0';
table = table(4:7,:)
nConfiguration = size(table,1);
configAcc = zeros(nConfiguration,1);
SVMLoss = zeros(nConfiguration,1); 

conf = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6)) <= 0.01;
posDataMat = dataMat(conf,:);
negDataMat = dataMat(~conf,:);
nSamples = 1000;
rand_samp_pos = randperm(size(posDataMat,1),nSamples);
rand_samp_neg = randperm(size(negDataMat,1),nSamples);

randDataPos = posDataMat(rand_samp_pos,:);
randDataNeg = negDataMat(rand_samp_neg,:);
trainDat = [randDataPos;randDataNeg]; 
trainLabel = abs(trainDat(:,5)-trainDat(:,6))./trainDat(:,6) <= 0.01;
% shuffle 
newOrder = randperm(size(trainDat,1));
trainDat = trainDat(newOrder,2:4);
trainLabel = trainLabel(newOrder,:);

tickNames = cell(1,nConfiguration);
paramNames = {'maxVal ','dutyCycle ','IR '};% PSNR is not supported yet
for c = 1:nConfiguration
   % Train an svm for each configuration
   config = logical(table(c,:));
   fprintf('Training SVM model %d...',c)
   SVMModel = fitcsvm(trainDat(:,config),trainLabel,'Standardize',false);
   CVMdl = crossval(SVMModel);
   SVMLoss(c) = kfoldLoss(CVMdl);
   fprintf('Predicting X labels...\n')
   [label,score] = predict(SVMModel,trainDat(:,config));
   configAcc(c) = mean(label == trainLabel);
   tickNames{c} = strjoin(paramNames(config));
end

figure()
bar(1:nConfiguration,[configAcc,1-SVMLoss])
xticks(1:nConfiguration)
xticklabels(tickNames)
xtickangle(45)

%%
load('logRegOn100Frames.mat');
[~,prob] = trainedClassifier.predictFcn(dataMat(:,2:4));
probPos = prob(:,2);
labels = double(abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6)) <= 0.01);

th = 0:0.01:1;
true_pos_rate = zeros(size(th));
true_neg_rate = zeros(size(th));
for i = 1:numel(th)
    true_pos_rate(i) = sum((probPos>th(i)) .* labels) ./ sum(labels);
    true_neg_rate(i) = sum((probPos<=th(i)) .* (1-labels)) ./ sum(1-labels);
end

subplot(1,2,1)
mean_rate = mean([true_pos_rate;true_neg_rate]);
plot(th,mean_rate); xlabel('threshold');ylabel('mean rates');title('average between TP and TN');
[maxv,I] = max(mean_rate);
txt = strcat('\leftarrow', sprintf('(TNR,TPR)=(%.2f,%.2f)',true_neg_rate(I),true_pos_rate(I)));
text(th(I),mean_rate(I),txt)
hold on
plot(th(I),mean_rate(I),'r*')
t = th(I);
subplot(1,2,2)
plot(true_neg_rate,true_pos_rate); xlabel('true neg rate');ylabel('true pos rate');title('TP,TN by changing lambda');
AUC = sum( true_pos_rate.*(true_neg_rate-[0,true_neg_rate(1:end-1)]));
text(0.2,0.2,sprintf('AUC=%.3f',AUC))
hold on
plot(true_neg_rate(I),true_pos_rate(I),'r*')
txt = strcat('\leftarrow', sprintf('(%.2f,%.2f)',true_neg_rate(I),true_pos_rate(I)));
text(true_neg_rate(I),true_pos_rate(I),txt)


%% Extract the weights of the classifier and show the connection between confidence and distance error:
W = trainedClassifier.GeneralizedLinearModel.Coefficients{1:4,1};
getProb = @(X)  1./(1+exp( -X*W(2:4)-W(1)));
prob = getProb(dataMat(:,2:4));
depthError = abs(dataMat(:,5)-dataMat(:,6))./abs(dataMat(:,6));


[prob_sort,order] = sort(prob);
depthErrorSort = depthError(order);
labelsSort = labels(order);
plot(prob_sort(labelsSort==0),depthErrorSort(labelsSort==0),'r*' )
hold on 
plot(prob_sort(labelsSort==1),depthErrorSort(labelsSort==1),'g*' )
hold on 
plot([t,t],[max(depthErrorSort),min(depthErrorSort)])

%% Adjust the classifier to fit the conf net 
W = trainedClassifier.GeneralizedLinearModel.Coefficients{1:4,1};
getLogits = @(X)  X*W(2:4)+W(1);
logits = getLogits(dataMat(:,2:4));

t_logits = -log(1/t-1);
[logits_sort,order] = sort(logits);
depthErrorSort = depthError(order);
labelsSort = labels(order);
plot((logits_sort(labelsSort==0)),depthErrorSort(labelsSort==0),'r*' )
hold on 
plot((logits_sort(labelsSort==1)),depthErrorSort(labelsSort==1),'g*' )


%% The Classifier has a negative weight for IR, why?
close all

above3700 = zeros(1,length(results));
frameMeandERforHighIR = zeros(1,length(results)); 
for i=1:length(results)
%     depth_gt = single(results(i).gt.zImg);
%     depth_pipe = single(results(i).zImgRAW/8); 
    IR = single(results(i).iImgRAW);
%     dutyCycle = single(results(i).dutyCycle);
%     psnr = single(results(i).psnr);
%     maxVal = single(results(i).max_val);
    above3700(i) = sum(IR(:)>3700);
    dER = abs(single(results(i).gt.zImg(IR>3700))-single(results(i).zImgRAW(IR>3700)/8))./single(results(i).gt.zImg(IR>3700));
    frameMeandERforHighIR(i) = mean(dER);
end
frameMeandERforHighIR(isnan(frameMeandERforHighIR)) = 0;
[~,I] = sort(frameMeandERforHighIR,2,'descend');
for j = 1:10
    
    zIm = max(0,depth_read(depthFiles{results(I(j)).frameNum})*1000); %mm
    aIm = mean(imread(albdoFiles{results(I(j)).frameNum}),3)/255; %[0 1]
    outzImg = double(results(I(j)).zImg)/double(results(I(j)).regs.GNRL.zNorm);
    outzImg(outzImg==0)=nan;

    depthRE = abs(single(results(I(j)).gt.zImg)-single(results(I(j)).zImgRAW/8))./single(results(I(j)).gt.zImg);
    figure
    subplot(231)
    imagesc(depthRE<=0.01);title('GoodConfGT(G)')
    colorbar
    subplot(232)
    imagesc(aIm);title('intensity(G)')
    colorbar
    subplot(233)
    imagescNAN(results(I(j)).zImgRAW/8);title('depth(R)')
    colorbar
    subplot(234)
    depthRE(results(I(j)).iImgRAW<=3700) = 0;
    imagesc(depthRE);title('depthRE(R)')
    colorbar
    subplot(235)
    imagesc(results(I(j)).cImgRAW);title('confidence(R)')
    colorbar
    subplot(236)
    imagesc(results(I(j)).iImgRAW);title('IR(R)')
    colorbar
    fprintf('done\n');

end