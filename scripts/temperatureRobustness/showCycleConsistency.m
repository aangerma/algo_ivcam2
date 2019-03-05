function showCycleConsistency(frames,tmpBinEdges,regs,refTmp,refTmpIndex)
%% Show the x,y,rtd diff from ref in each cycle.
meanDiff = zeros(numel(tmpBinEdges)-1,numel(frames),3);
rmsDiff = zeros(numel(tmpBinEdges)-1,numel(frames),3);


for i = 1:numel(frames)
    % Split frames by temperature
    framesPerTemperature = groupFramesByTemp(frames(i),tmpBinEdges,'ldd');
    meanRXY = cellfun(@(c) meanRtdXY(c,regs), framesPerTemperature,'UniformOutput' , 0 );
    
    
    for t = 1:numel(meanRXY)
        if isempty(meanRXY{t})
           continue; 
        end
        
        diff = meanRXY{t} - meanRXY{refTmpIndex};
        meanDiff(t,i,:) = nanmean((diff));
        
%         rmsDiff(t,i,:) = rms(abs(diff(~isnan(diff(:,1)),:)));
    end
end

figure,
subplot(311),
plot((tmpBinEdges(1:end-1)+tmpBinEdges(2:end))*0.5,meanDiff(:,:,1))
title('Mean Rtd diff Per cycle')
subplot(312),
plot((tmpBinEdges(1:end-1)+tmpBinEdges(2:end))*0.5,meanDiff(:,:,2))
title('Mean X diff Per cycle')
subplot(313),
plot((tmpBinEdges(1:end-1)+tmpBinEdges(2:end))*0.5,meanDiff(:,:,3))
title('Mean Y diff Per cycle')

end
function meanRXY = meanRtdXY(frames,regs)
if isempty(frames)
    meanRXY = [];
    return;
end
rpt = reshape([frames.rpt],[20*28,size(frames(1).rpt,2),numel(frames)]);
meanRXY = median(rpt,3);
[x,y] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(meanRXY(:,2),regs),meanRXY(:,3),regs,[],1);
meanRXY(:,2:3) = [x,y];
if size(meanRXY,2) > 3
    meanRXY(:,4:end) = [];
end
end
