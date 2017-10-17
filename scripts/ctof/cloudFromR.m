function v=cloudFromR(rtd,k)
[h,w]=size(rtd);

[yg,xg]=ndgrid(linspace(-1,1,h),linspace(-1,1,w));
yg = ((yg-k(2,3))/k(2,2));
xg = ((xg-k(1,3))/k(1,1));
xyz = [xg(:) yg(:) ones(w*h,1)];
xyz = xyz./sqrt(sum(xyz.^2,2));

r = rtd/2;
xyz = xyz.*r(:);
v = reshape(xyz,h,w,3);
end