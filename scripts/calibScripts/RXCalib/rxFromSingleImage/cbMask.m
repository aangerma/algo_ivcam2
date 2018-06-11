function [msk] = cbMask(cbIm)
%find CB points
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = detectCheckerboardPoints(normByMax(cbIm)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
N = (bsz(1)-1)*(bsz(2)-1);

pc(1,:) = p(1,:)+0.5*(p(1,:) - p(bsz(1)+1,:));
pc(2,:) = p(bsz(1)-1,:)+0.5*(p(bsz(1)-1,:) - p(2*(bsz(1)-1)-1,:));
pc(3,:) = p(N,:)+0.5*(p(N,:) - p(N-(bsz(1)-1)-1,:));
pc(4,:) = p(N-(bsz(1)-1)+1,:)+0.5*(p(N-(bsz(1)-1)+1,:) - p(N-2*(bsz(1)-1)+2,:));

% pc = p([1,bsz(1)-1,N,N-(bsz(1)-1)+1],:);

msk = poly2mask(pc(:,1),pc(:,2),size(cbIm,1),size(cbIm,2));
% tabplot;
% imagesc(cbIm)
% tabplot;
% imagesc(msk.*cbIm)
end

