function [ vectorFramesData ] = framesDataVectors( framesData )
%% This function recieves the framesData (data.framesData) of the data struct that is saves in the ATC and in Algo2Val and rearanges it so it will be easier to use them

if isfield(framesData,'temp')
    temp = [framesData.temp];
    fnames = fieldnames(temp);
    for i = 1:numel(fnames)
        vectorFramesData.(fnames{i}) = [temp.(fnames{i})];
    end
end
if isfield(framesData,'time')
    vectorFramesData.time = [framesData.time];
end
if isfield(framesData,'maVoltage')
    vectorFramesData.maVoltage = [framesData.maVoltage];
end
if isfield(framesData,'vBias')
    vectorFramesData.vBias = reshape([framesData.vBias],3,[]);
end
if isfield(framesData,'iBias')
    vectorFramesData.iBias = reshape([framesData.iBias],3,[]);
end
if isfield(framesData,'flyback')
    vectorFramesData.flyback = {framesData.flyback};
end
if isfield(framesData,'ptsWithZ')
    vectorFramesData.ptsWithZ = reshape([framesData.ptsWithZ],size(framesData(end).ptsWithZ,1),size(framesData(end).ptsWithZ,2),numel(framesData));
    vectorFramesData.validCB = all(~isnan(vectorFramesData.ptsWithZ(:,1,:)),3);
end
if isfield(framesData,'irStat')
    irStat = [framesData.irStat];
    vectorFramesData.irStatMean = [irStat.mean];
end
if isfield(framesData,'cStat')
    cStat = [framesData.cStat];
    vectorFramesData.cStatMean = [cStat.mean];
end
if isfield(framesData,'confPts')
    vectorFramesData.confPts = reshape([framesData.confPts],size(framesData(end).confPts,1),size(framesData(end).confPts,2),numel(framesData));
end
if isfield(framesData,'verticalSharpnessRGB')
    vectorFramesData.verticalSharpnessRGB = [framesData.verticalSharpnessRGB];
end
if isfield(framesData,'horizontalSharpnessRGB')
    vectorFramesData.horizontalSharpnessRGB = [framesData.horizontalSharpnessRGB];
end

end

