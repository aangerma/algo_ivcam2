
points3d = 100*randn(100,3);% points3d is a Nx3 point cloud
points3d(:,3) = abs(points3d(:,3));
regs.DEST.baseline = 31;
regs.DEST.baseline2 = 31^2;
% Option 1: 
% The range (distance from xyz to tx) plus the distance to rx
rtd1=sqrt(sum(points3d.^2,2))+sqrt(sum((points3d-[double(regs.DEST.baseline),0,0]).^2,2));

% Option 2:
% Using Law of cosines
range = sqrt(sum(points3d.^2,2));
sing=points3d(:,1)./range;
C=2*range*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd2=range+sqrt(range.^2-C);

plot(rtd1-rtd2)