function Kopt = OptimizeKmatForAngDist(regs, origK, xPixInterpolant, yPixInterpolant, x, y, polyCoef)
    
    %% setting original pixels
    [yy, xx] = ndgrid(y, x);
    origPixX = xx(:);
    origPixY = yy(:);
    
    in.vertices = [origPixX, origPixY, ones(length(x)*length(y),1)] * inv(origK)';
    out = Utils.convert.SphericalToCartesian(in, regs, 'inverse');
    origAngX = double(out.angx);
    origAngY = double(out.angy);
    
    %% applying angular error & optimizing K
    nDist = size(polyCoef,1);
    Kopt = zeros(3,3,nDist);
    for iDist = 1:nDist
        angX = polyval(polyCoef(iDist,:,1), origAngX);
        angY = polyval(polyCoef(iDist,:,2), origAngY);
        pixX = xPixInterpolant(angX, angY);
        pixY = yPixInterpolant(angX, angY);
        
        Vmat = [in.vertices(:,[1,3]), zeros(size(in.vertices,1),2); zeros(size(in.vertices,1),2), in.vertices(:,[2,3])];
        Pmat = [pixX; pixY];
        Kmat = (Vmat'*Vmat)\Vmat'*Pmat;
        Kopt(:,:,iDist) = [Kmat(1), 0, Kmat(2); 0, Kmat(3), Kmat(4); 0, 0, 1];
    end
end