function out = SphericalToCartesian(in, regs, mode)
    % SphericalToCartesian
    %   Converts ideal (i.e. error-free) spherical coordinates (with RTD instead of R) to Cartesian coordinates, and vice versa.
    %   Geometrical inputs are expected to be Nx1 (spherical) or Nx3 (Cartesian).
        
    angles2xyz = @(angx,angy) [cosd(angy).*sind(angx), sind(angy), cosd(angy).*cosd(angx)]';
    laserIncidentDir = angles2xyz(regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
    
    if strcmp(mode, 'forward') % spherical to Cartesian
        % Direction calculation
        applyReflection = @(mirrorDir) bsxfun(@plus,laserIncidentDir, -bsxfun(@times, 2*laserIncidentDir'*mirrorDir, mirrorDir));
        applyFOVex = @(v) Calibration.aux.applyFOVex(v, regs)';
        vUnit = applyFOVex(applyReflection(angles2xyz(in.angx/2, in.angy/2))); % Nx3
        % Range calculation
        sing = vUnit(:,2);
        baseline = -regs.DEST.baseline; % baseline in regs.DEST is represented with a reversed Y axis (i.e. upward)
        r = 0.5 * (in.rtd.^2 - regs.DEST.baseline2) ./ (in.rtd - baseline*sing); % Nx1
        % Cartesian representation
        out.vertices = r.*vUnit; % Nx3
        
    elseif strcmp(mode, 'backward') % Cartesian to spherical
        % RTD calculation
        calcDist = @(v) sqrt(sum(v.^2,2));
        rxPos = [0; -regs.DEST.baseline; 0]'; % baseline in regs.DEST is represented with a reversed Y axis (i.e. upward)
        r = calcDist(in.vertices);
        out.rtd = r + calcDist(in.vertices - rxPos);
        % Angular calculation
        applyFOVexInv = @(v) Calibration.aux.applyFOVexInv(v, regs);
        applyReflectionInv = @(v) normr(v - laserIncidentDir');
        xyz2angles = @(v) [atand(v(:,1)./v(:,3)), asind(v(:,2))];
        vUnit = in.vertices./r;
        angles = xyz2angles(applyReflectionInv(applyFOVexInv(vUnit)));
        out.angx = angles(:,1)*2;
        out.angy = angles(:,2)*2; 
        
    else
        error('Illegal mode: mode can be either ''forward'' or ''backward''.')
        
    end
    
end
     
            