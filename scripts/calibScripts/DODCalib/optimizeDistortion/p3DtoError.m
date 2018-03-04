function [e,grads] = p3DtoError(p);


tileSizeMM = 30;
h=size(p,1);
w=size(p,2);
pxyz=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(pxyz,[],3)';
valid = ~isnan(sum(xyzmes));
distMat = @(m) (sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
distMatMeas = distMat(xyzmes(:,valid));
distMatRef = distMat(ptsOpt(:,valid));
emat=(distMatMeas-distMatRef).^2;
e = mean(emat(:));
grads = calcGrads(xyzmes,ptsOpt);

end

function grads = calcGrads(p,pRef)
% p is a 3x(9*13) matrix. 
% The grads matrix should be 3x(9*13). The gradient in respect to each
% variable in p.
N = size(p,2);
diffMatAxis = @(m,axis) (m(axis,:)-m(axis,:)');
distMat = @(m) (sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
currDiffMat = distMat(p) - distMat(pRef);
dmat = cat(3,currDiffMat*diffMatAxis(p,1),currDiffMat*diffMatAxis(p,2),currDiffMat*diffMatAxis(p,3));
grads = squeeze(8/N.^2*sum(dmat,2));
end