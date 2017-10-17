function seg = planeTriIntersection(abcd,triXYZ)
%{

%plane to triangle intersection
N = 15;
[x,y] = meshgrid(1:N);
tri = delaunay(x,y);
z = peaks(N);
v = [x(:) y(:) z(:)]';
vv=permute(reshape(v(:,tri'),3,3,[]),[2 1 3]);
seg={};
n = [0.1 -0.1 1 -1 ];
n = n/norm(n(1:3));
for i=1:size(vv,3)
seg{i} = Simulator.aux.planeTriIntersection(n,vv(:,:,i));
end

trimesh(tri,x,y,z)
[xx,yy,zz] = meshgrid([1 N],[1 N],[-N N]);
          plnvert=isosurface(xx, yy, zz, n(1)*xx+n(2)*yy+n(3)*zz+n(4),0);
          patch(plnvert,'facecolor','r','facealpha',.2,'edgecolor','none');
for i=1:size(vv,3)
if(~isempty(seg{i}))
line(seg{i}(:,1),seg{i}(:,2),seg{i}(:,3),'color','r','linewidth',3)
end
end
%}
abcd=abcd(:);
triXYZ = bsxfun(@minus,triXYZ,[0 0 -abcd(4)]);
n=abcd(1:3);
d = triXYZ*n(:)>0;
z = triXYZ*n(:)==0;
if(all(d) || all(~d) || any(z))
    seg=[];
    return;
end
tmplt=[ 0 0 1 ; 0 1 0 ; 1 0 0 ; 1 1 0 ; 1 0 1 ; 0 1 1];
ni=[ 1 2   ; 1  3 ;   2 3 ; 1 2   ; 1   3 ;   2 3];
mi=[    3 ;   2   ; 1     ;     3 ;   2   ; 1    ];
indx = find(arrayfun(@(x) all(d==tmplt(x,:)'),1:6),1);
i0=mi(indx);
i1=ni(indx,1);
i2=ni(indx,2);


seg(1,:) = linePlaneIntersection(n,triXYZ(i1,:)',triXYZ(i0,:)');
seg(2,:) = linePlaneIntersection(n,triXYZ(i2,:)',triXYZ(i0,:)');


seg = bsxfun(@plus,seg,[0 0 -abcd(4)]);
end

function p = linePlaneIntersection(n,v1,v0)
nn = v1-v0;
s=-n'*v0/(n'*(nn));
p  = v0+s*nn;

end

