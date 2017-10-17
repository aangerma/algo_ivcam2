function [r,a] = raytrace2d(tri,v,albdo,xyz,sensorT)
%{
2D  raytracer
Inputs:
tri      - Nx3 triangles vertices of v;
v        - Mx3 xyz vertices
a        - Nx1 facets albedo
xyz      - Kx3 xyz projecting rays originating at (0,0,0)
sensorT  - 1x3 sensor location
Outputs:
r - Kx1 distances of each ray from the facets
a - Kx1 albedo    of each ray from the facets
            Y
      Z |  / ****
        | / ****
        |/  **
        +------> X

   
  Z            Z
  |--+         |--+
  |   \        |   \
  | H  |       | V  |
  +------->X   +------->Y
%}
CHUNK_MAX_SIZE = 2e7;

assert(size(tri,2)==3);
assert(size(v,2)==3);
assert(size(xyz,2)==3);
assert(size(albdo,2)==1);

XYZ_CHUNK_MAX = floor(CHUNK_MAX_SIZE/size(tri,1));

% xyz = bsxfun(@times,xyz,1./sqrt(sum(xyz.^2,2)));

nChunks = ceil(size(xyz,1)/XYZ_CHUNK_MAX);
chnkSz = ceil(size(xyz,1)/nChunks);
r = nan(size(xyz,1),2);
a = nan(size(xyz,1),1);

for i=1:nChunks
    ind = (i-1)*chnkSz+1:min(size(xyz,1),chnkSz*i);
    
    if(useGPU())
        [r(ind,:),a(ind)]=raytrace2d_GPU(tri,v,albdo,xyz(ind,:),sensorT);
    else
        error('GPU not found!');
    end
end
end
function [r,a] = raytrace2d_GPU(tri,v,albdo,xyz,sensorT)

% rayTriangleDistance(pt(n,1),pt(n,2),pt(n,3),npt(n,1),npt(n,2),npt(n,3),v(tri(tn,1),1)',v(tri(tn,1),2)',v(tri(tn,1),3)',   v(tri(tn,2),1)',v(tri(tn,2),2)',v(tri(tn,2),3)',   v(tri(tn,3),1)',v(tri(tn,3),2)',v(tri(tn,3),3)')


xyzG = gpuArray(xyz);
origin = [0 0 0];
H = arrayfun( @rayTriangleDistance, ...
    origin(1),origin(2),origin(3),...
    xyzG(:,1),xyzG(:,2),xyzG(:,3), ...
    v(tri(:,1),1)',v(tri(:,1),2)',v(tri(:,1),3)', ...
    v(tri(:,2),1)',v(tri(:,2),2)',v(tri(:,2),3)', ...
    v(tri(:,3),1)',v(tri(:,3),2)',v(tri(:,3),3)' );
[r,ind]=min(H,[],2);
clear H
%oclusion
if(any(sensorT~=0))
    pt = xyzG.*[r r r];
    npt = bsxfun(@minus,pt,sensorT);
    npt = bsxfun(@rdivide,npt,sqrt(sum(npt.^2,2)));
    
        H = arrayfun( @rayTriangleDistance, ...
        sensorT(1),sensorT(2),sensorT(3),...
        npt(:,1),npt(:,2),npt(:,3), ...
        v(tri(:,1),1)',v(tri(:,1),2)',v(tri(:,1),3)', ...
        v(tri(:,2),1)',v(tri(:,2),2)',v(tri(:,2),3)', ...
        v(tri(:,3),1)',v(tri(:,3),2)',v(tri(:,3),3)' );
    [r2,ind]=min(H,[],2);
    pt2 = bsxfun(@plus,npt.*[r2 r2 r2],sensorT);
    e=sum((pt2-pt).^2,2);
%     r = (r2+r)/2;
    r(e>sqrt(eps))=inf;
    r2(e>sqrt(eps))=inf;
%     pt = xyzG.*[r r r];
%     npt = bsxfun(@minus,sensorT,pt);
%     npt = bsxfun(@rdivide,npt,sqrt(sum(npt.^2,2)));
%     pt = pt+sqrt(eps)*npt;
%     H = arrayfun( @rayTriangleDistance, ...
%         pt(:,1),pt(:,2),pt(:,3),...
%         npt(:,1),npt(:,2),npt(:,3), ...
%         v(tri(:,1),1)',v(tri(:,1),2)',v(tri(:,1),3)', ...
%         v(tri(:,2),1)',v(tri(:,2),2)',v(tri(:,2),3)', ...
%         v(tri(:,3),1)',v(tri(:,3),2)',v(tri(:,3),3)' );
%     clear pt npt
% 
%     occ=~all(isinf(H),2);
%     r(occ)=inf;
else
    r2=r;
end
r = gather(r);
r2 = gather(r2);
% r=[r r2];
r=[r r2];


a = albdo(ind);
%reduce albedo acording to angle between projector and surface normal.
%assumin lambertian surfaces, all intensitiny is pearded evnangly to all
%directions
% patchNorm = cross(v(tri(ind,2),:)-v(tri(ind,1),:),v(tri(ind,3),:)-v(tri(ind,1),:),2);
% patchNorm = bsxfun(@times,patchNorm,1./sqrt(sum(patchNorm.^2,2)));
%a = a.*max(0,sum(xyz.*patchNorm,2))
a(any(isinf(r),2))=0;
end


function [r,a] = raytrace2d_CPU(tri,v,albdo,xyz,sensorT)

origin = [0 0 0];
rtdWrapper = @(o,xyz,i) rayTriangleDistance(...
    o(:,1),o(:,2),o(:,3),...
    xyz(:,1),xyz(:,2),xyz(:,3), ...
    v(tri(i,1),1)',v(tri(i,1),2)',v(tri(i,1),3)', ...
    v(tri(i,2),1)',v(tri(i,2),2)',v(tri(i,2),3)', ...
    v(tri(i,3),1)',v(tri(i,3),2)',v(tri(i,3),3)' );


H = nan(size(xyz,1),size(tri,1));
parfor i=1:size(tri,1)
    H(:,i)=arrayfun(@(x) rtdWrapper(origin,xyz(x,:),i),1:size(xyz,1)); %#ok
end
[r,ind]=min(H,[],2);

if(any(sensorT~=0))
    pt = xyz.*[r r r];
    npt = bsxfun(@minus,sensorT,pt);
    npt = bsxfun(@rdivide,npt,sqrt(sum(npt.^2,2)));
    
    H = nan(size(xyz,1),size(tri,1));
    parfor i=1:size(tri,1)
        H(:,i)=arrayfun(@(x) rtdWrapper(pt(x,:)+sqrt(eps)*npt(x,:),npt(x,:),i),1:size(xyz,1)); %#ok
    end
    
    clear pt npt
    occ=~all(isinf(H),2);
    r(occ)=inf;
end

patchNorm = cross(v(tri(ind,2),:)-v(tri(ind,1),:),v(tri(ind,3),:)-v(tri(ind,1),:),2);
patchNorm = bsxfun(@times,patchNorm,1./sqrt(sum(patchNorm.^2,2)));
a = abs(sum(xyz.*patchNorm,2).*albdo(ind));
end

function o=useGPU()
o=true;
try
    gpuDevice(1);
catch
    o=false;
end
end


function r=rayTriangleDistance(...
    ox,oy,oz,...
    dx,dy,dz,...
    p0x,p0y,p0z,...
    p1x,p1y,p1z,...
    p2x,p2y,p2z)

%{
patch([p0x p1x p2x],[p0y p1y p2y],[p0z p1z p2z],'r');
    hold on
    plot3(ox,oy,oz,'ro');
    quiver3(ox,oy,oz,dx,dy,dz,100)
    plot3(cx,cy,cz,'go')
%}

e1x = p1x-p0x;
e1y = p1y-p0y;
e1z = p1z-p0z;
% e2 = p2-p0;
e2x = p2x-p0x;
e2y = p2y-p0y;
e2z = p2z-p0z;



[nx,ny,nz] = crossProduct(e1x,e1y,e1z,e2x,e2y,e2z);
denum = (nx*dx+ny*dy+nz*dz);
if(denum==0)
    r=inf;
    return;
end
num = (nx*(p0x-ox)+ny*(p0y-oy)+nz*(p0z-oz));

r=num/denum;
if(r<0)
    r=inf;
    return;
end
cx=ox+r*dx;
cy=oy+r*dy;
cz=oz+r*dz;
e3x = cx-p0x;
e3y = cy-p0y;
e3z = cz-p0z;


nrm = (e1x^2*e2y^2 + e1x^2*e2z^2 - 2*e1x*e2x*e1y*e2y - 2*e1x*e2x*e1z*e2z + e2x^2*e1y^2 + e2x^2*e1z^2 + e1y^2*e2z^2 - 2*e1y*e2y*e1z*e2z + e2y^2*e1z^2);
if(nrm==0)
    r=inf;
    return;
end

p1=e2x^2 + e2y^2 + e2z^2;
p2=e1x*e2x + e1y*e2y + e1z*e2z;
a=1/nrm*(e3x*((e1x*p1) - (e2x*p2)) + e3y*((e1y*p1) - (e2y*p2)) + e3z*((e1z*p1) - (e2z*p2)));
if(a<0 || a>1)
    r = inf;
    return;
end
p3=e1x^2 + e1y^2 + e1z^2;
b=1/nrm*(e3x*((e2x*p3) - (e1x*p2)) + e3y*((e2y*p3) - (e1y*p2)) + e3z*((e2z*p3) - (e1z*p2)));
if(b<0 || b>1 || a+b>1)
    r = inf;
    return;
end

end


function [w1,w2,w3] = crossProduct(u1,u2,u3,v1,v2,v3)
w1 = u2*v3 - u3*v2;
w2 = u3*v1 - u1*v3;
w3 = u1*v2 - u2*v1;
end


