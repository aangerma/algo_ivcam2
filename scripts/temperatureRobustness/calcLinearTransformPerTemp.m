function transformationPerTemp = calcLinearTransformPerTemp(framesPerTemperature,refTmpIndex)

transformationPerTemp = cell(size(framesPerTemperature));
refFrames = framesPerTemperature{refTmpIndex};
refRpt = reshape([refFrames.rpt],[20*28,3,numel(refFrames)]);
refValidPoints = ~isnan(sum(sum(refRpt,3),2));

%% For each temp, find the optimal linear anx transformation
for i = 1:numel(framesPerTemperature)
   frames = framesPerTemperature{i};
   if isempty(frames)
       continue; 
   end
   % Get the valid points;
   currRpt = reshape([frames.rpt],[20*28,3,numel(frames)]);
   currValidPoints = ~isnan(sum(sum(currRpt,3),2));
   validPoints = logical(refValidPoints.*currValidPoints);
   currRefRpt = mean(refRpt(validPoints,:,:),3);
   currRpt = mean(currRpt(validPoints,:,:),3);
   [transformationPerTemp{i}.angxA,transformationPerTemp{i}.angxB] = linearTransform(currRpt(:,2),currRefRpt(:,2));
   [transformationPerTemp{i}.angyA,transformationPerTemp{i}.angyB] = linearTransform(currRpt(:,3),currRefRpt(:,3));
   transformationPerTemp{i}.rtdOffset = mean(currRefRpt(:,1))-mean(currRpt(:,1));
end


end

function [a,b] = linearTransform(x1,x2)
A = [x1,ones(size(x1))];
res = inv(A'*A)*A'*x2;
a = res(1);
b = res(2);
end