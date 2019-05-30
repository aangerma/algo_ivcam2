function [minRangeScaleModRef, ModRefDec] = calibrateMinRange(hw,calibParams,runParams,fprintff)

%% capture frames
minModprc=0 ;
LaserDelta=2; % decimal
FramesNum=10;

[LaserPoints,maxMod_dec,Frames] = Calibration.presets.captureVsLaserMod(hw,minModprc,LaserDelta,FramesNum,true);
%% Detecting ROI on low laser image
[whiteCenter,blackCenter,ROI_Coffset]=detectROI(Frames{1}(1).i,runParams);
%% analyzing white and black patch
imsize=size(Frames{1}(1).i);
Wmax=[]; Wmean=[];Bmin=[]; 
for i=1:length(Frames)
%      IRmat=reshape([Frames{i}.i],imsize(1),imsize(2),FramesNum);IR=mean(IRmat,3);
    IR=Frames{i}.i;
    wpatch=IR(round(whiteCenter(2)-ROI_Coffset(2)):round(whiteCenter(2)+ROI_Coffset(2)),round(whiteCenter(1)-ROI_Coffset(1)):round(whiteCenter(1)+ROI_Coffset(1)));
    bpatch=IR(round(blackCenter(2)-ROI_Coffset(2)):round(blackCenter(2)+ROI_Coffset(2)),round(blackCenter(1)-ROI_Coffset(1)):round(blackCenter(1)+ROI_Coffset(1)));
    %     figure(); imagesc(IR); hold all;
    %     rectangle('position', [round(whiteCenter(1)-ROI_Coffset(1)),round(whiteCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
    %     rectangle('position', [round(blackCenter(1)-ROI_Coffset(1)),round(blackCenter(2)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
    [Wmax(i),Wmean(i),~]= getIRvalues(wpatch);
    [~,~,Bmin(i)]= getIRvalues(bpatch);
    
end

DR=double(Wmax-Bmin);
diffDR=diff(DR);diffWmean=diff(Wmean);
p=polyfit(LaserPoints,DR,2);
 
lp=[LaserPoints,LaserPoints(end)+LaserDelta:LaserDelta:2*LaserPoints(end)];
fittedline=p(1)*lp.^2+p(2)*lp+p(3);

ParbMaxX=-p(2)/(2*p(1));
if(maxMod_dec<ParbMaxX)
    ModRefDec=maxMod_dec;
else
    ModRefDec=round(ParbMaxX);
end
minRangeScaleModRef=ModRefDec/maxMod_dec; 
    
if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(1,3,1);
    plot(LaserPoints,Wmax,LaserPoints,Wmean); title('IR values- white patch');xlabel('laser modulation [dec]'); legend('max', 'mean');grid minor;
    subplot(1,3,2);hold all;
    plot(lp,fittedline);plot(LaserPoints,DR); title('DR: Wmax-Bmin');xlabel('laser modulation [dec]');grid minor
    subplot(1,3,3);
    plot(LaserPoints,double(Wmax)-Wmean); title(' Wmax-Wmean white patch');xlabel('laser modulation [dec]');grid minor;

    subplot(1,3,2);scatter(ModRefDec,fittedline(lp==ModRefDec)); 

    Calibration.aux.saveFigureAsImage(ff,runParams,'SRpresetLaerCalib','PresetDir');
end

assert(p(1)<0 ,'MinRange preset calibration failed: first parabola coefficient is possitive');     

end
function [max,mean,min]= getIRvalues(im)
im=im(:);
mean = nanmean(im);
max=prctile(im,98);
min=prctile(im,1);
end

function [whiteCenter,blackCenter,ROI_Coffset]=detectROI(im,runParams)
% detect corners and centers
[pts,gridsize] = Validation.aux.findCheckerboard(im,[]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
ff = Calibration.aux.invisibleFigure;
imagesc(im); hold on;

x=pts(:,1); y=pts(:,2);X=reshape(x,gridsize); Y=reshape(y,gridsize);
patchNum=(gridsize(1)-1)*(gridsize(2)-1);

xcenter=(X(1:end-1,1:end-1)+X(1:end-1,2:end))./2;xcenter=xcenter(:);
ycenter=(Y(1:end-1,1:end-1)+Y(2:end,1:end-1))./2;ycenter=ycenter(:);
recsize=[mean(diff(mean(X,1))),mean(diff(mean(Y,2)))];

scatter(xcenter(:),ycenter(:),'+','MarkerEdgeColor','r','LineWidth',1.5);
%% extract white and black ROI
th=0.8; % ROI size
ROI_Coffset=th*recsize./2;
for j=1:patchNum
    patch=im(round(ycenter(j)-ROI_Coffset(2)):round(ycenter(j)+ROI_Coffset(2)),round(xcenter(j)-ROI_Coffset(1)):round(xcenter(j)+ROI_Coffset(1)));
    meanPatch(j)=mean(patch(:));
    rectangle('position', [round(xcenter(j)-ROI_Coffset(1)),round(ycenter(j)-ROI_Coffset(2)),2*ROI_Coffset(1),2*ROI_Coffset(2)]);
end
[~,whitePatchix]=max(meanPatch);
whiteCenter=[xcenter(whitePatchix),ycenter(whitePatchix)];
[p, l]=ind2sub([gridsize(1)-1,gridsize(2)-1],whitePatchix);
blackPatchix=sub2ind([gridsize(1)-1,gridsize(2)-1],p,l-1);
blackCenter=[xcenter(blackPatchix),ycenter(blackPatchix)];
scatter(whiteCenter(1),whiteCenter(2),'+','MarkerEdgeColor','w','LineWidth',1.5);
scatter(blackCenter(1),blackCenter(2),'+','MarkerEdgeColor','k','LineWidth',1.5);

Calibration.aux.saveFigureAsImage(ff,runParams,'ROIforSRpresetLaerCalib','PresetDir');

end