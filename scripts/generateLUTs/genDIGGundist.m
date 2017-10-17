clear
im = imread('D:\ohad\data\lidar\EXP\20170713\Non_Safe_Center\record_01\record_01_ir.png');
xyz = io.readBin('D:\ohad\data\lidar\EXP\20170713\Non_Safe_Center\record_01\record_01.binv');
[x,y,z]=deal(xyz(:,:,1),xyz(:,:,2),xyz(:,:,3));
[pts,bsz]=detectCheckerboardPoints(im);
bsz=bsz-1;
ind = sub2ind(size(im),round(pts(:,2)),round(pts(:,1)));
pts = [x(ind),y(ind) z(ind)];
abc=[pts(:,1:2) ind*0+1]\pts(:,3);
planeNorm = [abc(1:2);-1];
planeNorm = planeNorm/norm(planeNorm);
planeOffset = [0;0;abc(3)];
ptsP=pts-((pts-planeOffset')*planeNorm)*planeNorm';
ptsPQ=permute(reshape(ptsP',[3 bsz]),[2 3 1]);
[yo,xo]=ndgrid(linspace(-1,1,bsz(1)),linspace(-1,1,bsz(2)));
%projective transoft of cornerst in optgrid (1,1) (1,end) (end,1) (end,end) to ptsPQ
%project optgrid to IR image
%find shift vector fiels

plot3(pts(:,1),pts(:,2),pts(:,3),'.',ptsP(:,1),ptsP(:,2),ptsP(:,3),'og',ptso(:,1),ptso(:,2),ptso(:,3),'+c');
plotPlane([abc(1) abc(2) -1 abc(3)],'facecolor','r','edgecolor','none');
% axis equal
return

imagesc(im);
colormap gray
hold on
plot(pts(:,1),pts(:,2),'.','markersize',20);
for i=1:size(pts,1)
    text(pts(i,1),pts(i,2),num2str(i));
end
hold off

c = reshape(pts(:,1),bsz-1)+1j*reshape(pts(:,2),bsz-1);
[yg,xg]=ndgrid(linspace(min(imag(c(:))),max(imag(c(:))),size(c,1)),linspace(min(real(c(:))),max(real(c(:))),size(c,2)));
o = xg+1j*yg;

