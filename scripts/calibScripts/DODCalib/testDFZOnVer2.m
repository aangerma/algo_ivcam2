% load('\\invcam450\d\source\ivcam20\camdata.mat')
% load('\\invcam450\d\source\ivcam20\samsimdataWbaseLine.mat')

fw = Pipe.loadFirmware('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\initScriptVer2');
recordspath = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedDataVer2';
[regs,luts] = fw.get();
verbose = 1;

basenames = {'headacheCB','largeCB','largeWithregularCB','regularCB','regularDoubleCB'};
N = [6,4,4,14,12];
sz = [5.1,48.7,0,30,30];
%%Read all
for n = 1:numel(basenames)
    for i = 0:N(n)-1
        fname = fullfile(recordspath,strcat(basenames{n},num2str(i,'_%0.2d'),'.mat'));
        load(fname)
        d.sz = sz(n);
        darr.(basenames{n})(i+1) = d;
    end
end


%% show images 1 by 1
baseN = 4;
for i = 0:N(baseN)-1
    fname = fullfile(recordspath,strcat(basenames{baseN},num2str(i,'_%0.2d'),'.mat'));
    load(fname)
    tabplot; imagesc(d.i);
end

%% Read All 24 images into a struct array. Train the DFZ on a all at once.

[xoutTrain,eTrain,eFitTrain] = multiCalibDFZ(darr,regs,1,0);
[xoutVal,eVal,eFitVal] = multiCalibDFZ(darr,regs,1,1);

%% output a configuration file
fw.setRegs(xoutTrain,'');
[regs,luts] = fw.get();
fw.genMWDcmd([],'DFZConfig24Imgs.txt');
save 'fw.mat' 'fw'


%{
Checked my resulting configuration on our regular CB target and got:
X0:     63.33 60.55 5078.14 0.96 0.70 0.00 0.00 eAlex: 1.04 eFit: 2.06 
Xfinal: 63.43 60.47 5082.62 1.30 0.87 -0.00 -0.00 eAlex: 0.86 eFit: 1.95 

Which is great. I know that the DFZ can converge for an even better result
for a single image, but 1.04 is lower than the average error trained on all
24.

Checked my resulting configuration on our large CB target and got:
X0:     63.33 60.55 5078.14 0.96 0.70 0.00 0.00 eAlex: 8.35 eFit: 9.55 
Xfinal: 62.59 59.87 5085.75 2.25 -0.17 -0.00 -0.00 eAlex: 3.47 eFit: 6.88 

Which is now. I know that the DFZ can converge for an even better result
for a single image, but 1.04 is lower than the average error trained on all
24.
 

%}
%% Train on 2 images and test on all
baseN = 4;
useI = [8,10];
[regsTrain,~,~] = multiCalibDFZ(darr.(basenames{baseN})(useI),regs,1,0);
x0 = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV 0 0]);

for i = 1:N(baseN)
    [~,eGeom(i),eFit(i)] = multiCalibDFZ(darr.(basenames{baseN})(i),regs,1,1,x0);
end
histogram(eGeom),xlabel('Error Bins'),ylabel('Occupance'),title('Error Histogram For Images')
mean(eGeom),std(eGeom)

%% Train on all pairs and evaluate the result on all others
err = zeros(N,N,N);
for i = 1:N
    for j = 1:N
        if j > i
            continue;
        end
        useI = [i,j];
        [regsTrain,~,~] = multiCalibDFZ(darr(useI),regs,1,0);
        x0 = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV 0 0]);
        for k = 1:N
            [~,err(i,j,k),~] = multiCalibDFZ(darr(k),regs,0,1,x0);   
        end
    end
end

meanErr = mean(err,3);
meanErr = meanErr + meanErr';
meanErr(logical(eye(N))) = meanErr(logical(eye(N)))/2;
stdErr = std(err,[],3);
stdErr = stdErr + stdErr';
stdErr(logical(eye(N))) = stdErr(logical(eye(N)))/2;

figure
subplot(121);
imagesc(meanErr),title('Pairwise Mean Errors'),colorbar
subplot(122);
imagesc(stdErr),title('Pairwise STD Errors'),colorbar

save 'pairsResult.mat' 'meanErr' 'stdErr'
%% Train on 2 candidates 
useI = [7,8];
[regsTrain,~,~] = multiCalibDFZ(darr(useI),regs,1,0);
x0 = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
dx = double([2,2,10,0,0]);

ang = [0 -pi/2; 0 pi/2; ...
    0 0; pi/2 0; pi 0; 3*pi/2 0; ...
    0 -pi/4; pi/2 -pi/4; pi -pi/4; 3*pi/2 -pi/4; ...
    0 pi/4; pi/2 pi/4; pi pi/4; 3*pi/2 pi/4; ...
    ];

for i = 1:size(ang,1)
    theta = ang(i,1); phi = ang(i,2);
    [rout,~,~,~] = multiCalibDFZ(darr(useI),regs,0,0,x0+dx.*[cos(theta)*cos(phi),sin(theta)*cos(phi),sin(phi),0,0]);
    x(i,:) = double([rout.FRMW.xfov rout.FRMW.yfov rout.DEST.txFRQpd(1) rout.FRMW.laserangleH rout.FRMW.laserangleV]);
end
% Evaluate all x on all the dataset. And then evaluate the average.
for i = 1:size(x,1)
    [~,eGeom(i),eFit(i)] = multiCalibDFZ(darr,regs,0,1,x(i,:));
end
histogram(eGeom),xlabel('Error Bins'),ylabel('Occupance'),title('Error Histogram For Images')
mean(eGeom),std(eGeom)

% Evaluate mean x on all the dataset. 
[~,eGeomMean,eFitMean] = multiCalibDFZ(darr,regs,1,1,mean(x));


% From two images [9,17] got an average and std of:
% average: [62.71,60.02,5068.8,1.029,0.565]
% std:     [0.6824    0.6922   11.0505    0.1357    0.2609]
% eGeom = 1.1234
% all images together I get the following :
% average: [63   ,60.2,5073,0,0]
% std:     [0.27    0.28   4.25    0.05    0.066]
% eGeom = 1.1034

% the original Got eGeom 1.1239

% I repeated the experiment with [7,8] and got:
% average: [62.2 ,59.94,5063,0,0]
% std:     [0.59    0.61   8.46    0.1357    0.19]
% the global error decreased by 0.02 when using the average instead of the
% initial result. Same as before.

%% Read couble image, detect the two checkerboards and split the image into two
%% show images 1 by 1

baseN = 5;
darrTest = darr.regularCB;
dar = darr.regularDoubleCB;
for i = 1:N(baseN)
    tabplot; imagesc(dar(i).i);
    tabplot; imagesc(dar(i).z);
end
% chose an image:
for j = 1:12
ind = j;
d = dar(ind);
% Detect one of the CB
[p,~] = detectCheckerboardPoints(d.i);
assert(size(p,1) == 117)
% check if it left or right
isLeft = mean(p(:,1)) < size(d.i,2)/2;

Iremained = d.i;
Iremained(:,uint16(round(min(p(:,1))))-1:uint16(round(max(p(:,1))))+1) = 0;
[p2,~] = detectCheckerboardPoints(Iremained);
assert(size(p2,1) == 117)
% Decide which is the left
pIsLeft = mean(p(:,1))<mean(p2(:,1));
middleX = uint16(0.5*(mean(p(:,1))+mean(p2(:,1))));
dsplit(1) = d;dsplit(2) = d;
dsplit(1).i(:,middleX:end) = 0;
dsplit(2).i(:,1:middleX) = 0;

% Train on both
[regsTrain,~,~] = multiCalibDFZ(dsplit,regs,1,0);
x0both = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);

% train on each seperately
% [regsTrain,~,~] = multiCalibDFZ(dsplit(1),regs,1,0);
% x0left = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
% [regsTrain,~,~] = multiCalibDFZ(dsplit(2),regs,1,0);
% x0right = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);


% Evaluate on all the regular images

[~,eGeomBoth(j),eFitBoth] = multiCalibDFZ(darrTest,regs,0,1,x0both);
end
% [~,eGeomLeft,eFitLeft] = multiCalibDFZ(darrTest,regs,0,1,x0left);
% [~,eGeomRight,eFitRight] = multiCalibDFZ(darrTest,regs,0,1,x0right);

% For fair comparision, let us train on each single image and apply to all
% the rest:
for i = 1:numel(darrTest)
    [regsTrain,~,~] = multiCalibDFZ(darrTest(i),regs,1,0);
    x0 = double([regsTrain.FRMW.xfov regsTrain.FRMW.yfov regsTrain.DEST.txFRQpd(1) regsTrain.FRMW.laserangleH regsTrain.FRMW.laserangleV]);
    [~,eGeom(i),eFit(i)] = multiCalibDFZ(darrTest,regs,0,1,x0);
end


    

