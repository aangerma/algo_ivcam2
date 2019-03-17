function [table,results] = generateFWTable(framesData,regs,calibParams,runParams,fprintff)

% Bin frames according to fw loop requirment.
% Generate a linear fix for angles and an offset for rtd

% •	All values are fixed point 8.8
% •	Range is [35,66] – row for every 1 degree
% •	Linear interpolation
% •	Averaging of 10 last LDD temperature measurements every second. Temperature sample rate is 10Hz. 
% •	Replace “Reserved_512_Calibration_1_CalibData_Ver_20_00.txt” with ~“Algo_Thermal_Loop_512_ 1_CalibInfo_Ver_21_00.bin” 
% •	In case table does not exist, continue working with old thermal loop
invalidFrames = arrayfun(@(j) isempty(framesData(j).ptsWithZ),1:numel(framesData));
framesData = framesData(~invalidFrames);

tempVec = [framesData.temp];
tempVec = [tempVec.ldd];

refTmp = regs.FRMW.dfzCalTmp;
tmpBinEdges = (calibParams.fwTable.tempBinRange(1):calibParams.fwTable.tempBinRange(2)) - 0.5;

if ~isempty(runParams)
    ff = Calibration.aux.invisibleFigure;
    histogram(tempVec,25.5:80.5)
    title('Frames Per Ldd Temperature Histogram'); grid on;xlabel('Ldd Temperature');ylabel('count');
    Calibration.aux.saveFigureAsImage(ff,runParams,'Heating',sprintf('Histogram_Frames_Per_Temp'));
end

refBinIndex = 1+floor((refTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));



% tmpBinIndices(tmpBinIndices < 1) = nan;
% tmpBinIndices(tmpBinIndices < 1) = nan;



framesPerTemperature = Calibration.thermal.medianFrameByTemp(framesData,tmpBinEdges,tmpBinIndices);
results.framesPerTemperature = framesPerTemperature;

if all(all(isnan(framesPerTemperature(refBinIndex,:,:))))
    fprintff('Self heat didn''t reach algo calibration temperature. Calib temperature: %2.1f.\n',refTmp);
    table = [];
    return;
end
    
[angXscale,angXoffset] = linearTransformToRef(framesPerTemperature(:,:,2),refBinIndex);
[angYscale,angYoffset] = linearTransformToRef(framesPerTemperature(:,:,3),refBinIndex);
[destTmprtOffset] = constantTransformToRef(framesPerTemperature(:,:,1),refBinIndex);

nTableRows = numel(tmpBinEdges);

nonEmptyT = find(~isnan(destTmprtOffset));
usedTmpIndex = max(min(1:nTableRows,nonEmptyT(end)),nonEmptyT(1));

angXscale = angXscale(usedTmpIndex)';
angXoffset = angXoffset(usedTmpIndex)';
angYscale = angYscale(usedTmpIndex)';
angYoffset = angYoffset(usedTmpIndex)';
destTmprtOffset = destTmprtOffset(usedTmpIndex)';

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

        
        
results.table = table;
results.framesPerTemperature = framesPerTemperature;


if ~isempty(runParams)
    titles = {'dsmXscale','dsmYscale','dsmXoffset','dsmYoffset','RTD Offset'};
    xlabels = 'Ldd Temperature [degrees]';
    for i = 1:5
        ff = Calibration.aux.invisibleFigure;
        plot(tmpBinEdges,table(:,i));
        title(titles{i});
        xlabel(xlabels);
        Calibration.aux.saveFigureAsImage(ff,runParams,'FWTable',titles{i});
    end
end



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
