function [ data ] = calcLOSErrorByTemp( framesPerTemperature,regs,refTmpIndex )

refFrames = framesPerTemperature{refTmpIndex};
refRpt = reshape([refFrames.rpt],[20*28,size(refFrames(1).rpt,2),numel(refFrames)]);
refValidPoints = ~isnan(sum(sum(refRpt,3),2));
rptErrorsPerTempMax = nan(3,numel(framesPerTemperature));
rptErrorsPerTempRMS = nan(3,numel(framesPerTemperature));
Temp = nan(numel(framesPerTemperature),1);
%% For each temp, find the optimal linear anx transformation
for i = 1:numel(framesPerTemperature)
   frames = framesPerTemperature{i};
   if isempty(frames)
       continue; 
   end
   % Get the valid points;
   currRpt = reshape([frames.rpt],[20*28,size(frames(1).rpt,2),numel(frames)]);
   currValidPoints = ~isnan(sum(sum(currRpt,3),2));
   validPoints = logical(refValidPoints.*currValidPoints);
   currRefRpt = mean(refRpt(validPoints,:,:),3);
   currRpt = mean(currRpt(validPoints,:,:),3);
   % Calculate the errors per temp:
   % angX,angY,rtd - max,RMS
   [xRef,yRef] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(currRefRpt(:,2),regs),currRefRpt(:,3),regs,[],1);
   [x,y] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(currRpt(:,2),regs),currRpt(:,3),regs,[],1);
   
   
%    rptErrorsPerTempMax(1,i) = max(abs(currRefRpt(:,1)-currRpt(:,1)));
   rptErrorsPerTempMax(1,i) = prctile(abs(currRefRpt(:,1)-currRpt(:,1)),95);
   rptErrorsPerTempRMS(1,i) = rms(currRefRpt(:,1)-currRpt(:,1));
%    rptErrorsPerTempMax(2:3,i) = max(abs([x,y]-[xRef,yRef]));
   rptErrorsPerTempMax(2:3,i) = prctile(abs([x,y]-[xRef,yRef]),95);

   rptErrorsPerTempRMS(2:3,i) = rms([x,y]-[xRef,yRef]);
   
   
   Temp(i) = frames(1).temp.ldd;
   
   
   
end
% figure,
% subplot(231);
% plot(Temp,rptErrorsPerTempMax(1,:));title('Max Rtd Diff From Ref');xlabel('Temperature'); ylabel('mm');
% subplot(234);
% plot(Temp,rptErrorsPerTempRMS(1,:));title('RMS Rtd Diff From Ref');xlabel('Temperature'); ylabel('mm');
% subplot(232);
% plot(Temp,rptErrorsPerTempMax(2,:));title('Max X Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');
% subplot(235);
% plot(Temp,rptErrorsPerTempRMS(2,:));title('RMS X Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');
% subplot(233);
% plot(Temp,rptErrorsPerTempMax(3,:));title('Max Y Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');
% subplot(236);
% plot(Temp,rptErrorsPerTempRMS(3,:));title('RMS Y Pixel Diff From Ref');xlabel('Temperature'); ylabel('Pixels');

data.rptErrorsPerTempMax = rptErrorsPerTempMax;
data.rptErrorsPerTempRMS = rptErrorsPerTempRMS;
data.Temp = Temp;
end

