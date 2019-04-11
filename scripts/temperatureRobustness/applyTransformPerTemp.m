function transformedFrames = applyTransformPerTemp(framesPerTemperature,transformationPerTemp)
transformedFrames = cell(size(framesPerTemperature));
for i = 1:numel(transformationPerTemp)
   trans =  transformationPerTemp{i};
   if isempty(trans)
       continue;
   end
   
   frames = framesPerTemperature{i};

   transformedFrames{i} = arrayfun(@(f) applyT(f,trans),frames);
   
   
end


end

function frame = applyT(frame,trans)
frame.rpt(:,1) = frame.rpt(:,1) + trans.rtdOffset;
frame.rpt(:,2) = frame.rpt(:,2)*trans.angxA + trans.angxB;
frame.rpt(:,3) = frame.rpt(:,3)*trans.angyA + trans.angyB;

end