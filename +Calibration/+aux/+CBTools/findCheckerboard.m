function [pt, gridSize] = findCheckerboard(ir, expectedGridSize,cornersDetectionThreshold)

if(~exist('expectedGridSize','var'))
    expectedGridSize=[];
end
if(~exist('cornersDetectionThreshold','var'))
    cornersDetectionThreshold=0.35;
end
if isa(ir, 'char')
    ir = io.readBin(ir);
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
        [pt,bsz] = vision.internal.calibration.checkerboard.detectCheckerboard(I, smoothKers(i), cornersDetectionThreshold);
        gridSize = bsz - 1;
        if (isequal(gridSize, expectedGridSize) || (isempty(expectedGridSize) && any(gridSize > 1)))
            break;
        end
    end

if isempty(pt)
    return; 
end
%%
% vis(ir,pt);

% order checkers Points as matlab axis direction
x=pt(:,1); y=pt(:,2);
X=reshape(x,gridSize); Y=reshape(y,gridSize);
% 2 first Point
deltaXrows=mean(X(end,:)-X(1,:)); 
deltaXcols=mean(X(:,end)-X(:,1));
if(abs(deltaXrows)>abs(deltaXcols)) %X inds run on rows instead of columns
    X=X'; Y=Y';
    gridSize=flip(gridSize); 
end
deltaXcols=mean(X(:,end)-X(:,1));
deltaYrows=mean(Y(end,:)-Y(1,:));

if deltaXcols<0 % points are ordered in opposite x direction
    X=flip(X,2); Y=flip(Y,2);
end
if deltaYrows<0 % points are ordered in opposite y direction
    X=flip(X,1); Y=flip(Y,1);
end

pt(:,1)=X(:); pt(:,2)=Y(:);
% vis(ir,pt);


end

function []=vis(im,pt )
pointsNum=length(pt);
figure();
imagesc(im); hold on;
scatter(pt(:,1),pt(:,2),'+','MarkerEdgeColor','r','LineWidth',1.5);
txt=split(mat2str(1:pointsNum));
text(pt(:,1)+1,pt(:,2),txt);
end
