function [table,results,Invalid_Frames] = generateFWTable(data,calibParams,runParams,fprintff)
% Bin frames according to fw loop requirment.
% Generate a linear fix for angles and an offset for rtd

% •	All values are fixed point 8.8
% •	Range is [32,79] degrees – row for every 1 degree of Ldd for
% temperature offset fix
% •	Linear interpolation
% •	Averaging of 10 last LDD temperature measurements every second. Temperature sample rate is 10Hz. Same for vBias and Ibias 
% •	Replace “Reserved_512_Calibration_1_CalibData_Ver_20_00.txt” with ~“Algo_Thermal_Loop_512_ 1_CalibInfo_Ver_21_00.bin” 
% •	In case table does not exist, continue working with old thermal loop
framesData = data.framesData;
regs = data.regs;
invalidFrames = arrayfun(@(j) isempty(framesData(j).ptsWithZ),1:numel(framesData));
fprintff('Invalid frames: %.0f/%.0f\n',sum(invalidFrames),numel(invalidFrames));
framesData = framesData(~invalidFrames);
Invalid_Frames = sum(invalidFrames);

nBins = 48;
N = nBins+1;
tempData = [framesData.temp];
vBias = reshape([framesData.vBias],3,[]);
ldd = [tempData.ldd];
timev = [framesData.time];

%% Linear RTD fix
validPerFrame = arrayfun(@(x) ~isnan(x.ptsWithZ(:,1)),framesData,'UniformOutput',false)';
validPerFrame = cell2mat(validPerFrame);
validCB = all(validPerFrame,2);
rtdPerFrame = arrayfun(@(x) nanmean(x.ptsWithZ(validCB,1)),framesData);
refTmp = data.dfzRefTmp;
% a*ldd +b = rtdPerFrame;

startI = calibParams.fwTable.nFramesToIgnore+1;
verifyThermalSweepValidity(ldd, startI, calibParams.warmUp)
[a,b] = linearTrans(vec(ldd(startI:end)),vec(rtdPerFrame(startI:end)));

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    plot(ldd,rtdPerFrame,'*');
    title('RTD(ldd) and Fitted line');
    grid on;xlabel('Ldd Temperature');ylabel('mean rtd');
    hold on
    plot(ldd,a*ldd+b);
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('MeanRtd_Per_Temp'));
end
 
results.rtd.refTemp = refTmp;
results.rtd.slope = a;
if isfield(calibParams.fwTable, 'tempBinRes') % temporary patch until this field is always present
    binRes = calibParams.fwTable.tempBinRes;
else
    fprintff('WARNING: bin resolution not defined for thermal RTD table, using 1 as default...')
    binRes = 1;
end
fwBinCenters = calibParams.fwTable.tempBinRange(1):binRes:calibParams.fwTable.tempBinRange(2);
results.rtd.tmptrOffsetValues = -((fwBinCenters-refTmp)*results.rtd.slope)';

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    histogram(ldd,25.5:80.5)
    title('Frames Per Ldd Temperature Histogram'); grid on;xlabel('Ldd Temperature');ylabel('count');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Histogram_Frames_Per_Temp'));
end


%% Y Fix
% groupByVBias2
vbias2 = vBias(2,:);
minMaxVBias2 = minmax(vbias2);
maxVBias2 = minMaxVBias2(2);
minVBias2 = minMaxVBias2(1);
binEdges = linspace(minVBias2,maxVBias2,N);
dbin = binEdges(2)-binEdges(1);
binIndices = max(1,min(nBins,floor((vbias2-minVBias2)/dbin)+1));
refBinIndex = max(1,min(nBins,floor((regs.FRMW.dfzVbias(2)-minVBias2)/dbin)+1));
framesPerVBias2 = Calibration.thermal.medianFrameByTemp(framesData,nBins,binIndices);
if all(all(isnan(framesPerVBias2(refBinIndex,:,:))))
    fprintff('Self heat didn''t reach algo calibration vBias2. \n');
    table = [];
    return;
end

[results.angy.scale,results.angy.offset] = linearTransformToRef(framesPerVBias2(:,validCB,3),refBinIndex);
results.angy.minval = mean(binEdges(1:2));
results.angy.maxval = mean(binEdges(end-1:end));
results.angy.nBins = nBins;

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(131)
    plot((binEdges(1:end-1)+binEdges(2:end))*0.5,results.angy.scale);
    title('AngYScale per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYScale'); grid on;
    subplot(132)
    plot(timev,vBias(2,:));title('vBias2(t)'); xlabel('time [sec]'); ylabel('vBias2[v]'); grid on;
    subplot(133)
    plot((binEdges(1:end-1)+binEdges(2:end))*0.5,results.angy.offset);
    title('AngYOffset per vBias2'); xlabel('vBias2 (V)'); ylabel('AngYOffset'); grid on;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Scale and Offset Per vBias2'));
end


%% X Fix - groupByVBias1+3
vbias1 = vBias(1,:);
vbias3 = vBias(3,:);
[a,b] = linearTrans(vec(vbias1(startI:end)),vec(vbias3(startI:end)));


minmaxvbias1 = minmax(vbias1);
maxvbias1 = minmaxvbias1(2);
minvbias1 = minmaxvbias1(1);
p0 = [minvbias1,a*minvbias1 + b];
p1 = [maxvbias1,a*maxvbias1 + b];

t = linspace(0,1,N);
% For some p, find ||p - p1 + tgal(pend-p1)||^2
% tgal = (1/||(pend-p1||^2)*(pend-p1)*(p-p1)';
tgal = (1/norm(p1-p0)^2)*(p1-p0)*([vbias1(:),vbias3(:)]-p0)';
% figure,plot(tgal);
binEdges = t;
dbin = binEdges(2)-binEdges(1);
binIndices = max(1,min(nBins,floor((tgal)/dbin)+1));
refBinTGal = (1/norm(p1-p0)^2)*(p1-p0)*([regs.FRMW.dfzVbias(1),regs.FRMW.dfzVbias(3)]-p0)';
refBinIndex = max(1,min(nBins,floor((refBinTGal)/dbin)+1));
framesPerVBias13 = Calibration.thermal.medianFrameByTemp(framesData,nBins,binIndices);

if all(all(isnan(framesPerVBias13(refBinIndex,:,:))))
    fprintff('Self heat didn''t reach algo calibration vbias1/3.\n');
    table = [];
    return;
end


[results.angx.scale,results.angx.offset] = linearTransformToRef(framesPerVBias13(:,validCB,2),refBinIndex);
results.angx.p0 = p0;
results.angx.p1 = p1;
results.angx.nBins = nBins;


if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    subplot(132);
    pEdges = p0+t'.*(p1-p0);
    plot(vbias1,vbias3); hold on; plot(pEdges(:,1),pEdges(:,2),'o');title('vBias3(vBias1)'); xlabel('vBias1');ylabel('vBias3');grid on;
    subplot(131);
    plot(results.angx.scale);
    title('AngXScale per point'); xlabel('bin index'); ylabel('AngXScale'); grid on;
    subplot(133);
    plot(results.angx.offset);
    title('AngXOffset per point'); xlabel('bin index'); ylabel('AngXOffset'); grid on;
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Scale and Offset Per vBias13'));
end



angXscale = vec(results.angx.scale);
angXoffset = vec(results.angx.offset);
angYscale = vec(results.angy.scale);
angYoffset = vec(results.angy.offset);
destTmprtOffset = vec(results.rtd.tmptrOffsetValues);
    
% Convert to dsm values
dsmXscale = angXscale*regs.EXTL.dsmXscale;
dsmXoffset = (regs.EXTL.dsmXoffset*dsmXscale-2048*angXscale+angXoffset+2048)./dsmXscale;
dsmYscale = angYscale*regs.EXTL.dsmYscale;
dsmYoffset = (regs.EXTL.dsmYoffset*dsmYscale-2048*angYscale+angYoffset+2048)./dsmYscale;

table = [dsmXscale,...
            dsmYscale,...
            dsmXoffset,...
            dsmYoffset,...
            destTmprtOffset];

table = fillInnerNans(table);   
table = fillStartNans(table);   
table = flipud(fillStartNans(flipud(table)));   
results.table = table;

if ~isempty(runParams)
    titles = {'dsmXscale','dsmYscale','dsmXoffset','dsmYoffset','RTD Offset'};
    xlabels = 'Table Row';
    for i = 1:5
        ff = Calibration.aux.invisibleFigure;
        plot(table(:,i));
        title(titles{i});
        xlabel(xlabels);
        Calibration.aux.saveFigureAsImage(ff,runParams,'FWTable',titles{i});
    end
end

assert(~any(isnan(table(:))),'Thermal table contains nans \n');


end



function [offset] = constantTransformToRef(framesPerTemperature,refBinIndex)

nFrames = size(framesPerTemperature,1);  
target = framesPerTemperature(refBinIndex,:);
validT = ~isnan(target);
for i = 1:nFrames
    source = framesPerTemperature(i,:);
    valid = logical((~isnan(source)) .* validT);
    
    if any(valid)
        offset(i) = mean(target(valid)) - mean(source(valid));
    else
        offset(i) = nan;
    end
    
end

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
function table = fillStartNans(table)
    for i = 1:size(table,2)
        ni = find(~isnan(table(:,i)),1);
        if ni>1
            table(1:ni-1,i) = table(ni,i);
        end
    end
end
function tableNoInnerNans = fillInnerNans(table)
    tableNoInnerNans = table;
    
    for i = 1:size(table,2)
        col = table(:,i);
        nanRows = isnan(col);
        rowId = (1:size(table,1))';
        tableValid = col(~nanRows);
        rowValid = rowId(~nanRows);
        rowInvalid = rowId(nanRows);
        newVals = interp1q(rowValid,tableValid,rowInvalid);
        tableNoInnerNans(nanRows,i) = newVals;
    end

end
% function framesPerTemperatureHindSightFix = transformFrames(framesPerTemperature,angXscale,angXoffset,angYscale,angYoffset,destTmprtOffset,regs)
% %[rtd,angx,angy,pts,verts]
% tableSz = numel(angYscale);
% nTemps = size(framesPerTemperature,1);
% framesPerTemperatureHindSightFix = framesPerTemperature;
% angXscale(tableSz+1:nTemps) = angXscale(tableSz);
% angYscale(tableSz+1:nTemps) = angYscale(tableSz);
% angXoffset(tableSz+1:nTemps) = angXoffset(tableSz);
% angYoffset(tableSz+1:nTemps) = angYoffset(tableSz);
% destTmprtOffset(tableSz+1:nTemps) = destTmprtOffset(tableSz);
% 
% for i = 1:nTemps
%     currFrame = squeeze(framesPerTemperature(i,:,:));
%     currFrame(:,1) = currFrame(:,1) + destTmprtOffset(i);
%     currFrame(:,2) = currFrame(:,2)*angXscale(i) + angXoffset(i);
%     currFrame(:,3) = currFrame(:,3)*angYscale(i) + angYoffset(i);
%     [currFrame(:,4),currFrame(:,5)] = Calibration.aux.vec2xy(Calibration.aux.ang2vec(currFrame(:,2),currFrame(:,3),regs), regs); % Cheating here as I do not apply the undistort
%     
%     [oXYZ] = ang2vec(currFrame(:,2),currFrame(:,3),regs,[]);
%     
%     [currFrame(:,4),currFrame(:,5)] = Calibration.aux.vec2xy(Calibration.aux.ang2vec(currFrame(:,2),currFrame(:,3),regs), regs);
%     
% end
% 
% end

function verifyThermalSweepValidity(ldd, startI, warmUpParams)
if (startI >= 0.5*length(ldd))
    error('Too few frames left for thermal calibration (%d taken, %d ignored)', length(ldd), startI-1)
end
if (diff(warmUpParams.requiredTmptrRange)>0) % valid obligatory range
    if (min(ldd)>warmUpParams.requiredTmptrRange(1)) || (max(ldd)<warmUpParams.requiredTmptrRange(2))
        error('Thermal sweep %.1f-%.1f missed obligatory range [%d,%d]', min(ldd), max(ldd), warmUpParams.requiredTmptrRange(1), warmUpParams.requiredTmptrRange(2))
    end
end
end