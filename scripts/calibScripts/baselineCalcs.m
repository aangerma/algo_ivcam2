b = 40;
z = 300;
x = 200;
r1 = sqrt(z^2+x^2);
r2_L = sqrt(z^2+(x-b)^2);
r2_R = sqrt(z^2+(x+b)^2);

r = r1 + r1;
rL = r1 + r2_L;
rR = r1 + r2_R;

df = rL/2 - rR/2;
dL = rL/2 - r/2;
dR = rR/2 - r/2;


[y, x] = ndgrid(1:13, 1:9);




