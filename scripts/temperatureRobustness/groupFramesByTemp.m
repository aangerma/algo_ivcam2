function framesPerTemperature = groupFramesByTemp(frames,tmpBinEdges,tmpType)
framesPerTemperature = cell(1,numel(tmpBinEdges));
% Assign each frame to the right cell
for i = 1:numel(frames)
   iterFrames = frames{i}; 
   tmps = [iterFrames.temp];
   tmps = [tmps.(tmpType)];
   % Index per temp
   tmpIndex = 1+floor((tmps-tmpBinEdges(1))/(tmpBinEdges(2)-tmpBinEdges(1)));
   tmpIndex = min(max(tmpIndex,1),numel(tmpBinEdges));
   for k = min(tmpIndex):max(tmpIndex)
      framesPerTemp = iterFrames(tmpIndex == k);
      framesPerTemperature{k} = [framesPerTemperature{k},framesPerTemp];
   end
end

end
