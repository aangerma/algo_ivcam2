% load('\\invcam450\d\source\ivcam20\camdata.mat')
% load('\\invcam450\d\source\ivcam20\samsimdataWbaseLine.mat')

fw = Pipe.loadFirmware('\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\initScript');
recordspath = '\\tmund-MOBL1.ger.corp.intel.com\C$\git\ivcam2.0\scripts\calibScripts\DODCalib\DODCalibDataset\recordedData';

[regs,luts] = fw.get();
verbose = 1;
useLarge = 0;

if useLarge
   baseName = 'largeCB_';
   N = 3;
   sz = 48.7;
else
   baseName = 'regularCB_';
   N = 24;
   sz = 30;
end
for i = 0:N-1
    fname = fullfile(recordspath,strcat(baseName,num2str(i,'%0.2d'),'.mat'));
    load(fname)
    d.sz = sz;
    darr(i+1) = d;
end


%% Evaluate 1 by 1
eval = 0;
minerr = zeros(N/2,1);
outregs = zeros(N/2,5);
k= 1;
for i = 1:N
    for j = 1:N
        if i==j || j>i
           continue; 
        end
    %     fname = fullfile(recordspath,strcat(baseName,num2str(i,'%0.2d'),'.mat'));
    %     load(fname)
    % %     d.sz = sz;
    %     tabplot; imagesc(d.i);
        [xout,minerr(k),eFit] = multiCalibDFZ(darr([i,j]),regs,0,eval);
        if ~eval
            outregs(k,:) = double([xout.FRMW.xfov xout.FRMW.yfov xout.DEST.txFRQpd(1) xout.FRMW.laserangleH xout.FRMW.laserangleV]);
        end
        k = k+1
    end
end

histogram(minerr),xlabel('Error Bins'),ylabel('Occupance'),title('Error Histogram For 24 Images')
mean(minerr),std(minerr)
if ~eval
    mu=mean(outregs),st = std(outregs)
end
%% Read All 24 images into a struct array. Train the DFZ on a all at once.

[xoutTrain,eTrain,eFitTrain,darrNew] = multiCalibDFZ(darr,regs,1,0);

[xoutTrain2,eTrain2,eFitTrain2,darrNew2] = multiCalibDFZ(darrNew,xoutTrain,1,0);

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

%% Train on all singles and see std

[xoutTrain,eTrain,xBest] = multiCalibDsmFov(darr,regs,1,0);   

outregs = zeros(10,6);
for i = 1:10
    i
    [regsTrain,err(i),xBest] = multiCalibDsmFov(darr(i),regs,1,0);   
    outregs(i,:) = xBest;

end

mean(err), std(err)

mean(outregs),std(outregs)