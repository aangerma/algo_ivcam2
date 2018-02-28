function p3D = getCBPoints3D(d,regs)
% returns the 3D location of the checkerboard points given the current regs.
[v,~] = Pipe.z16toVerts(d.z,regs);
[p,bsz] = detectCheckerboardPoints(normByMax(d.i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
[yg,xg]=ndgrid(1:size(v,1),1:size(v,2));
it = @(k) interp2(xg,yg,k,reshape(p(:,1),bsz-1),reshape(p(:,2),bsz-1)); % Used to get depth and ir values at checkerboard locations.
p3D=cat(3,it(v(:,:,1)),it(v(:,:,2)),it(v(:,:,3))); % Convert coordinate system xyz. 

end

