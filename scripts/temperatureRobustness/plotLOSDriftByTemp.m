function [  ] = plotLOSDriftByTemp( framesPerTemperature,regs,tempStages,refTmpIndices )

for i = 1:numel(refTmpIndices)-1
   frame1 = framesPerTemperature{refTmpIndices(i)};
   frame2 = framesPerTemperature{refTmpIndices(i+1)};
   
   rpt1 = reshape([frame1.rpt],[20*28,size(frame1(1).rpt,2),numel(frame1)]);
   rpt1 = mean(rpt1,3);
   rpt2 = reshape([frame2.rpt],[20*28,size(frame2(1).rpt,2),numel(frame2)]);
   rpt2 = mean(rpt2,3);
   
   if i == 1
      figure; 
   end
   tabplot;
   [x1,y1] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(rpt1(:,2),regs),rpt1(:,3),regs,[],1); 
   [x2,y2] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(rpt2(:,2),regs),rpt2(:,3),regs,[],1); 
   quiver(x1,y1,x2-x1,y2-y1,'r');
   diffs = sqrt((x2-x1).^2+(y2-y1).^2);
   maxDrift = max(diffs);
   rmsDrift = rms(diffs(~isnan(diffs)));
   title(sprintf('LOS Movement by temp: %2.0f -> %2.0f, max=%2.2f, rms=%2.2f',tempStages(i),tempStages(i+1),maxDrift,rmsDrift))
end


end

