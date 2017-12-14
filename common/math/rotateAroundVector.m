function rot = rotateAroundVector(u,phi)
if(numel(u)==3 && numel(phi)==3)%two vectors, find rotation matrix
    v1=u(:)/norm(u);v2=phi(:)/norm(phi);
    u=cross(v2,v1);
    phi=acos(v1'*v2);
end
u = u/norm(u);
w=[0 -u(3) u(2);u(3) 0 -u(1);-u(2) u(1) 0];
rot = eye(3)+sin(phi)*w+(1-cos(phi))*w^2;
end
