% take the average X error and RTD error between: startTemp+2 degrees until end temperature-1 degree 
% load("\\ger\ec\proj\ha\RSG\SA_3DCam\TMund\F9010093\1.25Gui Runs\F9010093\TC11_thermostream_run3\validationData.mat");
% [rtdDriftQuality,xDriftQuality,yDriftQuality] = calcThermalScores(data.framesData);% Mean of x offset, Mean of y offset, Mean of rtd offset

function [errors] = calcThermalScores(data,calibParams,resolution)
framesData = data.framesData;
invalidFrames = arrayfun(@(j) isempty(framesData(j).ptsWithZ) | all(all(isnan(framesData(j).ptsWithZ))),1:numel(framesData));
framesData = framesData(~invalidFrames);
Hres=resolution(2); Vres=resolution(1);
tempVec = [framesData.temp];
tempVec = [tempVec.ldd];

nBins = calibParams.fwTable.nRows;
dLdd = (calibParams.fwTable.tempBinRange(2) - calibParams.fwTable.tempBinRange(1))/(nBins-1);
tmpBinEdges = linspace(calibParams.fwTable.tempBinRange(1),calibParams.fwTable.tempBinRange(2),nBins) - dLdd*0.5;
refBinIndex = 1+floor((data.dfzRefTmp-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
tmpBinIndices = 1+floor((tempVec-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));



framesPerTemperature = Calibration.thermal.medianFrameByTemp(framesData,nBins,tmpBinIndices);
    
[Xscale,Xoffset] = linearTransformToRef(framesPerTemperature(:,:,4)-single(Hres-1)/2,refBinIndex);
[Yscale,Yoffset] = linearTransformToRef(framesPerTemperature(:,:,5)-single(Vres-1)/2,refBinIndex);
[destTmprtOffset] = constantTransformToRef(framesPerTemperature(:,:,1),refBinIndex);

Xscale = Calibration.tables.fillInnerNans(Xscale');
Xoffset = Calibration.tables.fillInnerNans(Xoffset');
Yscale = Calibration.tables.fillInnerNans(Yscale');
Yoffset = Calibration.tables.fillInnerNans(Yoffset');
destTmprtOffset = Calibration.tables.fillInnerNans(destTmprtOffset');

valid = find(~isnan(Xscale));
validRange = (valid(1)+2):(valid(end)-1);

errors.xScale = rms( abs(Xscale(validRange)-1) );
errors.yScale = rms( abs(Yscale(validRange)-1) );
errors.xShift = rms( abs(Xoffset(validRange) ) );
errors.yShift = rms( abs(Yoffset(validRange) ) );
errors.rtdShit = rms( abs(destTmprtOffset(validRange) ) );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a,b] = linearTrans(x1,x2)
A = [x1,ones(size(x1))];
res = inv(A'*A)*A'*x2;
a = res(1);
b = res(2);
end
