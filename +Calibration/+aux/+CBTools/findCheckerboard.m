function [pt, gridSize] = findCheckerboard(ir, expectedGridSize)

if(~exist('expectedGridSize','var'))
    expectedGridSize=[];
end


ir_=ir;

ir_(isnan(ir_))=0;
% ir_ = histeq(normByMax(ir_));
ir_ = (normByMax(ir_));

% pt = Utils.findCheckerBoardCorners(ir_,boardSize,false);

smoothKers = [2 3 4 6 8];
I = im2single(ir_);
for i=1:length(smoothKers)
    %[pt,bsz]=detectCheckerboardPoints(ir_);
    [pt,bsz] = vision.internal.calibration.checkerboard.detectCheckerboard(I, smoothKers(i), 0.5);
    gridSize = bsz - 1;
    if (isequal(gridSize, expectedGridSize) || (isempty(expectedGridSize) && any(gridSize > 1)))
        break;
    end
end

end

