function framesPerTemperature = medianFrameByTemp(framesData,tmpBinEdges,tmpBinIndices)
for i = 1:numel(tmpBinEdges)
    currFrames = framesData(tmpBinIndices == i);
    if isempty(currFrames)
        framesPerTemperature(i,:,:) = nan(size(framesData(1).ptsWithZ));
        continue;
    end
    currData = reshape([currFrames.ptsWithZ],[size(currFrames(1).ptsWithZ,1),size(currFrames(1).ptsWithZ,2),numel(currFrames)]);
    framesPerTemperature(i,:,:) = median(currData,3);
    
end

end