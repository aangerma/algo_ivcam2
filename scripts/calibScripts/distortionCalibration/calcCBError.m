function cbError = calcCBError(frame,params)

squareSize = 30;
ir = frame(1).i;
z = frame(1).z;

[gridPoints, ~] = Validation.aux.findCheckerboard(ir, params.expectedGridSize);
p = Validation.aux.pointsToVertices(gridPoints, z, params.camera);
p = reshape(p,[params.expectedGridSize,3]);

cbError = gridError(p, squareSize);
end

function [emat] = gridError(p, squareSize)

h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*squareSize/2,linspace(-1,1,w)*(w-1)*squareSize/2);
ptsOpt = cat(3,ox,oy,zeros(h,w));


emat = zeros(h,w);
for i = 1:h
    for j = 1:w
        emat(i,j) = mean(mean(abs(sqrt(sum((p-p(i,j,:)).^2,3)) - sqrt(sum((ptsOpt-ptsOpt(i,j,:)).^2,3)))));
    end
end


end
