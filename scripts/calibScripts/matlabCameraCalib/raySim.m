NB = [0 0 1];
L = [0 0 -1];

RotZenith = rotSlow(0);
RotRay = rotSlow(0);

AX = -20:0.1:20;
AY = -12:0.1:12;
nx = length(AX);
ny = length(AY);
X = zeros(ny,nx);
Y = zeros(ny,nx);
for ix=1:nx
    for iy=1:ny
        n = NB*rotFast(AX(ix))*rotSlow(AY(iy))*RotZenith;
        r = L-2*(L*n')*n;
        r = r * RotRay;
        X(iy,ix) = r(1)/r(3);
        Y(iy,ix) = r(2)/r(3);
    end
end

figure; plot(X(:),Y(:),'.');

L2 = [0 0 -1];
NB = [0 0 1];
n2 = NB*rotFast(25)*rotSlow(35);
R2 = L2-2*(L2*n2')*n2;
