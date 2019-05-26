function [fixes] = calcFix(data,ref)
fixes.ref = ref;
nBins = 48;
N = nBins+1;
tempData = [data.framesData.temp];
vBias = reshape([data.framesData.vBias],3,[]);
ldd = [tempData.ldd];
timev = [data.framesData.time];
rtdPerFrame = arrayfun(@(x) nanmean(x.ptsWithZ(:,1)),data.framesData);
meanYPerFrame = arrayfun(@(x) nanmean(x.ptsWithZ(:,3)),data.framesData);

%% Linear RTD fix
figure;
plot(ldd,rtdPerFrame,'*');
% a*ldd +b = rtdPerFrame;
startI = round(numel(rtdPerFrame)/80);
X = [ldd(startI:end);ones(size(ldd(startI:end)))]';
ab = (X'*X)\X'*rtdPerFrame(startI:end)';
hold on
plot(ldd,ab(1)*ldd+ab(2));
title('RTD(ldd)');
 
fixes.rtd.refTemp = ref.Ldd;
fixes.rtd.slope = ab(1);
fwBinCenters = 32:79;
fixes.rtdTmptrOffsetValues = -((fwBinCenters-fixes.rtd.refTemp)*fixes.rtd.slope)';

figure,
tabplot;
plot(fwBinCenters,fixes.rtdTmptrOffsetValues);
title('rtd offset per ldd temperature'); xlabel('ldd temp (deg)'); ylabel('rtdOffset (mm)'); grid on;
%% Y Fix
% figure;
% plot(timev,vBias(2,:));
% 
% hold on
% plot(timev,meanYPerFrame);
% vbias2 = vBias(2,:)
% ldd2 = ldd([1:573,628:end])
% plot(ldd2,meanYPerFrame([1:573,628:end]),'*');


% groupByVBias2
vbias2 = vBias(2,:);
[minMaxVBias2] = minmax(vbias2);
minVBias2 = minMaxVBias2(1);
maxVBias2 = minMaxVBias2(2);
binEdges = linspace(minVBias2,maxVBias2,N);
dbin = binEdges(2)-binEdges(1);
binIndices = floor((vbias2-minVBias2)/dbin)+1;
refBinIndex = floor((ref.vBias(2)-minVBias2)/dbin)+1;
framesPerTemperature = medianFrameByTemp(data.framesData,nBins,binIndices);
% [angXscale,angXoffset] = linearTransformToRef(framesPerTemperature(:,:,2),refBinIndex);
[fixes.angy.scale,fixes.angy.offset] = linearTransformToRef(framesPerTemperature(:,:,3),refBinIndex);
fixes.angy.minval = minVBias2;
fixes.angy.maxval = maxVBias2;
fixes.angy.nBins = nBins;

tabplot;
subplot(131)
plot((binEdges(1:end-1)+binEdges(2:end))*0.5,fixes.angy.scale);
title('AngYScale per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYScale'); grid on;
subplot(132)
plot(timev,vBias(2,:));title('vBias2(t)'); xlabel('time [sec]'); ylabel('vBias2[v]'); grid on;
subplot(133)
plot((binEdges(1:end-1)+binEdges(2:end))*0.5,fixes.angy.offset);
title('AngYOffset per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYOffset'); grid on;

% groupByVBias1+3
vbias1 = vBias(1,:);
vbias3 = vBias(3,:);
X = [vbias1(startI:end);ones(size(ldd(startI:end)))]';
ab = (X'*X)\X'*vbias3(startI:end)';
% plot(vbias1,vbias3);
% hold on
% plot(vbias1,ab(1)*vbias1+ab(2));
% title('vbias3(vbias1)');

[minMaxvbias1] = minmax(vbias1);
minvbias1 = minMaxvbias1(1);
maxvbias1 = minMaxvbias1(2);
p0 = [minvbias1,ab(1)*minvbias1 + ab(2)];
p1 = [maxvbias1,ab(1)*maxvbias1 + ab(2)];

t = linspace(0,1,N);
% For some p, find ||p - p1 + tgal(pend-p1)||^2
% tgal = (1/||(pend-p1||^2)*(pend-p1)*(p-p1)';
tgal = (1/norm(p1-p0)^2)*(p1-p0)*([vbias1(:),vbias3(:)]-p0)';
% figure,plot(tgal);

binEdges = t;
dbin = binEdges(2)-binEdges(1);
binIndices = floor((tgal)/dbin)+1;
refBinTGal = (1/norm(p1-p0)^2)*(p1-p0)*([ref.vBias(1),ref.vBias(3)]-p0)';
refBinIndex = floor((refBinTGal)/dbin)+1;
framesPerTemperature = medianFrameByTemp(data.framesData,nBins,binIndices);
[fixes.angx.scale,fixes.angx.offset] = linearTransformToRef(framesPerTemperature(:,:,2),refBinIndex);
fixes.angx.p0 = p0;
fixes.angx.p1 = p1;
fixes.angx.nBins = nBins;

tabplot;
subplot(132);
pEdges = p0+t'.*(p1-p0);
plot(vbias1,vbias3); hold on; plot(pEdges(:,1),pEdges(:,2),'o');title('vBias3(vBias1)'); xlabel('vBias1');ylabel('vBias3');grid on;
subplot(131);
plot(fixes.angx.scale);
title('AngXScale per point'); xlabel('bin index'); ylabel('AngXScale'); grid on;
subplot(133);
plot(fixes.angx.offset);
title('AngXOffset per point'); xlabel('bin index'); ylabel('AngXOffset'); grid on;




end

function [anga,angb] = linearTransformToRef(framesPerTemperature,refBinIndex)

nFrames = size(framesPerTemperature,1);  
target = framesPerTemperature(refBinIndex,:);
validT = ~isnan(target);
for i = 1:nFrames
    source = framesPerTemperature(i,:);
    valid = logical((~isnan(source)) .* validT);
    
    if any(valid)
        [anga(i),angb(i)] = linearTrans(vec(source(valid)),vec(target(valid)));
    else
        anga(i) = nan;
        angb(i) = nan;
    end
    
end

end

function [a,b] = linearTrans(x1,x2)
A = [x1,ones(size(x1))];
res = inv(A'*A)*A'*x2;
a = res(1);
b = res(2);
end
function framesPerTemperature = medianFrameByTemp(framesData,nBins,tmpBinIndices)
for i = 1:nBins
    currFrames = framesData(tmpBinIndices == i);
    if isempty(currFrames)
        framesPerTemperature(i,:,:) = nan(size(framesData(1).ptsWithZ));
        continue;
    end
    currData = reshape([currFrames.ptsWithZ],[size(currFrames(1).ptsWithZ,1),size(currFrames(1).ptsWithZ,2),numel(currFrames)]);
    framesPerTemperature(i,:,:) = median(currData,3);
    
end

end