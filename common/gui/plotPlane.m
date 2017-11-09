function h = plotPlane(varargin)
vec = varargin{1};
mx = get(gca,'xlim');
my =get(gca,'ylim');
mz = get(gca,'zlim');
[xx,yy,zz] = meshgrid(mx, my, mz);
plnvert=isosurface(xx, yy, zz, vec(1)*xx+vec(2)*yy+vec(3)*zz+vec(4),0);
h=patch(plnvert,varargin{2:end});
end