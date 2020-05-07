function data = PreProcessing(regs, acData, dsmRegs, sz, origK)
    
    % los-to-pixel mapping
    [yPixGrid, xPixGrid] = ndgrid(1:double(sz(1)), 1:double(sz(2)));
    data.vertices = [xPixGrid(:), yPixGrid(:), ones(prod(sz),1)] * inv(origK)';
    rpt = Utils.convert.RptToVertices(data.vertices, regs, [], 'inverse');
    dsmRegsOrig = Utils.convert.applyAcResOnDsmModel(acData, dsmRegs, 'inverse');
    [losX, losY] = Utils.convert.applyDsm(rpt(:,2), rpt(:,3), dsmRegsOrig, 'inverse');
    data.losX = double(losX);
    data.losY = double(losY);
    data.xPixInterpolant = scatteredInterpolant(data.losX, data.losY, xPixGrid(:), 'linear');
    data.yPixInterpolant = scatteredInterpolant(data.losX, data.losY, yPixGrid(:), 'linear');
    
    % shift ratios calculation
    losShift = 1;
    
    shiftedLosX = data.losX + losShift; % horizontal shift
    shiftedVertices = ConvertLosToNormVertices(regs, dsmRegsOrig, shiftedLosX, data.losY);
    shiftRatio = [origK(1,1), origK(2,2), 1].*(shiftedVertices-data.vertices) / losShift;
    data.Lxx = reshape(shiftRatio(:,1),sz);
    data.Lyx = reshape(shiftRatio(:,2),sz);
    
    shiftedLosY = data.losY + losShift; % vertical shift
    shiftedVertices = ConvertLosToNormVertices(regs, dsmRegsOrig, data.losX, shiftedLosY);
    shiftRatio = [origK(1,1), origK(2,2), 1].*(shiftedVertices-data.vertices) / losShift;
    data.Lxy = reshape(shiftRatio(:,1),sz);
    data.Lyy = reshape(shiftRatio(:,2),sz);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vertices = ConvertLosToNormVertices(regs, dsmRegsOrig, losX, losY)
    
    rpt = 1000*ones(length(losX),3);
    [rpt(:,2), rpt(:,3)] = Utils.convert.applyDsm(losX, losY, dsmRegsOrig, 'direct');
    vertices = Utils.convert.RptToVertices(rpt, regs, [], 'direct'); %TODO: settle for polyUndistAndPitchFix and ang2vec
    vertices = vertices./vertices(:,3);
    
end
