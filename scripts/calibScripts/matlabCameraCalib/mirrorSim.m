% rotation around y-axis
rotFast = @(ang) [1 0 0; 0 cosd(ang) -sind(ang); 0 sind(ang) cosd(ang)];
rotSlow = @(ang) [cosd(ang) 0 sind(ang); 0 1 0; -sind(ang) 0 cosd(ang)];

%% no PBS
%NB = normr([-0.5 0 0.5]);
%L = [1 0 0];

MN = [0 0 1]; % mirror normal
L = [0 0 -1];%*RotZenith*RotZenith;

RotZenith = rotSlow(0.54)*rotFast(-0.02);
RotRay = rotSlow(0); % unit rotation

AX = -15:0.1:15;
AY = -10:0.1:10;
nx = length(AX);
ny = length(AY);
X = zeros(ny,nx);
Y = zeros(ny,nx);
for ix=1:nx
    for iy=1:ny
        n = MN*RotZenith*rotSlow(AX(ix))*rotFast(AY(iy));
        r = L-2*(L*n')*n;
        r = r * RotRay;
        X(iy,ix) = r(1)/r(3);
        Y(iy,ix) = r(2)/r(3);
    end
end

figure; plot(X(:),Y(:),'.');
figure; plot(atand(X(:)),atand(Y(:)),'.');
