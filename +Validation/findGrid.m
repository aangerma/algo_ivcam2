function [ptsX, ptsY] = findGrid(ir)

ir = double(ir);

ir(sum(ir(:,2:end-1),2)==0,:)=[];

ir_=ir;

ir_(isnan(ir_))=0;
ir_ = histeq(normByMax(ir_));
[pt,bsz]=detectCheckerboardPoints(ir_);

boardSize = bsz - 1;
if(any(boardSize < 2))
    error('Board is not detected');
end

ptsX = reshape(pt(:,1),boardSize);
ptsY = reshape(pt(:,2),boardSize);

end