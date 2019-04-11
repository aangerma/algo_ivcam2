function [transformationPerTemp,transformedFrames] = calcPitchTransformPerTemp(framesPerTemperature,refTmpIndex)
transformedFrames = cell(size(framesPerTemperature));

transformationPerTemp = cell(size(framesPerTemperature));
refFrames = framesPerTemperature{refTmpIndex};
refRpt = reshape([refFrames.rpt],[20*28,size(refFrames(1).rpt,2),numel(refFrames)]);
refValidPoints = ~isnan(sum(sum(refRpt,3),2));

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
   [transformationPerTemp{i}.angxA,transformationPerTemp{i}.angxB] = linearTransform(currRpt(:,2),currRefRpt(:,2));
   [transformationPerTemp{i}.angyA,transformationPerTemp{i}.angyB,transformationPerTemp{i}.angyPitch] = pitchTransform(currRpt(:,2:3),currRefRpt(:,2:3));
   transformationPerTemp{i}.rtdOffset = mean(currRefRpt(:,1))-mean(currRpt(:,1));
   
   transformedFrames{i} = arrayfun(@(f) applyT(f,transformationPerTemp{i}),frames);
   
end


end
function [a,b,p] = pitchTransform(x1,x2)
A = [x1(:,2),ones(size(x1(:,2))),x1(:,1)];
res = inv(A'*A)*A'*x2(:,2);
a = res(1);
b = res(2);
p = res(3);
end
function [a,b] = linearTransform(x1,x2)
A = [x1,ones(size(x1))];
res = inv(A'*A)*A'*x2;
a = res(1);
b = res(2);
end

function frame = applyT(frame,trans)
frame.rpt(:,1) = frame.rpt(:,1) + trans.rtdOffset;
frame.rpt(:,3) = frame.rpt(:,3)*trans.angyA + trans.angyB + frame.rpt(:,2)*trans.angyPitch;
frame.rpt(:,2) = frame.rpt(:,2)*trans.angxA + trans.angxB;

end