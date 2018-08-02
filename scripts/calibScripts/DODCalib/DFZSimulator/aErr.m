function [ e ] = aErr( p )
tileSizeMM = 30;
h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(p,[],3)';
distMat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
emat=abs(distMat(xyzmes)-distMat(ptsOpt));
e = mean(emat(:));


end

