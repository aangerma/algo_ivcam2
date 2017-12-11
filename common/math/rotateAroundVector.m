function rot = rotateAroundVector(u,phi)
u = u/norm(u);
w=[0 -u(3) u(2);u(3) 0 -u(1);-u(2) u(1) 0];
rot = eye(3)+sin(phi)*w+(1-cos(phi))*w^2;
end
