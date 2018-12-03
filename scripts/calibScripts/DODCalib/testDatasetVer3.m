%% Load the dataset
fw = Pipe.loadFirmware('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedDataVer3\initConfigCalib');
recordspath = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedDataVer3';
[regs,luts] = fw.get();
verbose = 1;
load(fullfile(recordspath,'d40','darr.mat'));
darr40 = darr;
load(fullfile(recordspath,'d40_+10','darr.mat'));
darr40_plus = darr;
load(fullfile(recordspath,'d40_-10','darr.mat'));
darr40_minus = darr;

load(fullfile(recordspath,'d50','darr.mat'));
darr50 = darr;
load(fullfile(recordspath,'d50_+10','darr.mat'));
darr50_plus = darr;
load(fullfile(recordspath,'d50_-10','darr.mat'));
darr50_minus = darr;


load(fullfile(recordspath,'d60','darr.mat'));
darr60 = darr;
load(fullfile(recordspath,'d60_+10','darr.mat'));
darr60_plus = darr;
load(fullfile(recordspath,'d60_-10','darr.mat'));
darr60_minus = darr;
 
load(fullfile(recordspath,'d_test','darr.mat'));
darr_test = darr;

darr_train = [darr40,darr40_plus,darr40_minus,darr50,darr50_plus,darr50_minus,darr60,darr60_plus,darr60_minus];

%% Get optimal configuration. Get the training and test errors:
[xoutTrain,eTrain,eFitTrain] = multiCalibDFZ(darr_train,regs,1,0);
xBest = double([xoutTrain.FRMW.xfov xoutTrain.FRMW.yfov xoutTrain.DEST.txFRQpd(1) xoutTrain.FRMW.laserangleH xoutTrain.FRMW.laserangleV]);
[~,eTest,eFitTest] = multiCalibDFZ(darr_test,regs,1,1,xBest);

%% Get avg and configuration std from 1 images from each state. Get Avg and STD of error as well.

xRes  = zeros(9,5,5);
eVal  = zeros(9,5);
eTest = zeros(9,5);

for di = 1:9
    indices = 1+(di-1)*5:di*5;
    for i = 1:5
        fprintf('Evaluating single [%d/%d]...\n',(di-1)*5+i,45);
        [regsTrain,~,~] = multiCalibDFZ(darr_train(indices(i)),regs,0,0);
        xRes(di,i,:) = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
        valI = ones(1,45);
        valI(indices(i)) = 0;
        valI = logical(valI);
        [~,eVal(di,i),~] = multiCalibDFZ(darr_train(valI),regs,0,1,xRes(di,i,:));
        [~,eTest(di,i),~] = multiCalibDFZ(darr_test,regs,0,1,xRes(di,i,:));
    end
end

resultTable = zeros(18,7);
resultTable(1:2:end,:) = [squeeze(mean(xRes,2)),mean(eVal,2),mean(eTest,2)]; 
resultTable(2:2:end,:) = [squeeze(std(xRes,[],2)),std(eVal,[],2),std(eTest,[],2)]; 
results.Singles = resultTable;
%% Now take for each combination of distances (6 combinations) 10  random pairs of  images and evaluate them.
xRes  = zeros(6,10,5);
eVal  = zeros(6,10);
eTest = zeros(6,10);

combs = [1,1; 1,2; 1,3; 2,2; 2,3; 3,3];

rng(2);
pairs = randi([1 15],10,2);
for c = 1:6
    for i = 1:10
        tic
        fprintf('Evaluating pair [%d/%d]...',(c-1)*10+i,60);
        indices2use = [pairs(i,1)+15*(combs(c,1)-1) pairs(i,2)+15*(combs(c,2)-1)];
        [regsTrain,~,~] = multiCalibDFZ(darr_train(indices2use),regs,0,0);
        xRes(c,i,:) = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
        valI = ones(1,45);
        valI(indices2use) = 0;
        valI = logical(valI);
        [~,eVal(c,i),~] = multiCalibDFZ(darr_train(valI),regs,0,1,xRes(c,i,:));
        [~,eTest(c,i),~] = multiCalibDFZ(darr_test,regs,0,1,xRes(c,i,:));
        fprintf('Done. Took %2.2f[sec].\n',toc);
    end
end

resultTable = zeros(12,7);
resultTable(1:2:end,:) = [squeeze(mean(xRes,2)),mean(eVal,2),mean(eTest,2)]; 
resultTable(2:2:end,:) = [squeeze(std(xRes,[],2)),std(eVal,[],2),std(eTest,[],2)]; 


results.pairs = resultTable;
%% Now take triplets. 1 from each distance. Take 20 triplets.
xRes  = zeros(20,5);
eVal  = zeros(20,1);
eTest = zeros(20,1);

combs = [1,2,3];
rng(2);
triplets = randi([1 15],100,3);
triplets = unique(triplets,'rows','stable'); 
triplets = triplets(1:20,:);

for i = 1:20
    tic
    fprintf('Evaluating triplet [%d/%d]...',i,20);
    indices2use = triplets(i,:) + (combs-1)*15;
    [regsTrain,~,~] = multiCalibDFZ(darr_train(indices2use),regs,0,0);
    xRes(i,:) = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
    valI = ones(1,45);
    valI(indices2use) = 0;
    valI = logical(valI);
    [~,eVal(i),~] = multiCalibDFZ(darr_train(valI),regs,0,1,xRes(i,:));
    [~,eTest(i),~] = multiCalibDFZ(darr_test,regs,0,1,xRes(i,:));
    fprintf('Done. Took %2.2f[sec].\n',toc);
end


resultTable = zeros(2,7);
resultTable(1:2:end,:) = [squeeze(mean(xRes)),mean(eVal(:,1)),mean(eTest(:,1))]; 
resultTable(2:2:end,:) = [squeeze(std(xRes,[],1)),std(eVal(:,1)),std(eTest(:,1))]; 
results.Triplets = resultTable;
%% Load the headache targets. Use them for training and test on the regular 45 targets.
load(fullfile(recordspath,'d_headache','darr.mat'));
dache = darr;
tabplot; imagesc(dache(1).i)
dache(1).sz = 5.1;
[regsTrain,eTrain,eFitTrain] = multiCalibDFZ(dache(1),regs,1,0);
xBest = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
[~,eVal,eFitVal] = multiCalibDFZ(darr_train,regs,0,1,xBest);
[~,eTest,eFitTest] = multiCalibDFZ(darr_test,regs,0,1,xBest);
% eVal is 1.3471
% eTest is 2.2529