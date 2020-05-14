function [uvRMS,VDepth] = calcUVMappingErr(frame,params,plotFlag,depthVertices)
if ~exist('plotFlag','var')
    plotFlag = 0;
end

if isfield(params,'cbGridSz')
    CB = CBTools.Checkerboard (frame.i,'expectedGridSize',params.cbGridSz); 
    ptsDepth = CB.getGridPointsList;

    CB = CBTools.Checkerboard (frame.yuy2,'expectedGridSize',params.cbGridSz);
    ptsRGB = CB.getGridPointsList;
else
    if isfield(params,'targetType')
        CB = CBTools.Checkerboard (frame.i,'targetType',params.targetType);
        ptsDepth = CB.getGridPointsList;
        params.cbGridSz = CB.gridSize;
        
        CB = CBTools.Checkerboard (frame.yuy2,'targetType',params.targetType);
        ptsRGB = CB.getGridPointsList;
    else
        error('calcUVMappingErr: Problem in params defenitions for CBTools.Checkerboard');
    end
end


% Depth corners to vertices
zVals = interp2(single(frame.z)/single(params.zMaxSubMM),ptsDepth(:,1),ptsDepth(:,2));
VDepth = (pinv(params.Kdepth)*([ptsDepth-1,ones(prod(params.cbGridSz),1)]'))'.*zVals;

if exist('depthVertices','var')
    VDepth = depthVertices';
end

% Project to RGB
uv = params.rgbPmat * [VDepth ones(size(VDepth,1),1)]';
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';
uvMap = [u,v];
uvMapUndist = du.math.distortCam(uvMap', params.Krgb, params.rgbDistort)' + 1;

if exist('params','var') && isfield(params,'rgbTfix') && params.rgbTfix
    if ~isfield(params,'rgbTmat')
        error('No matrix was given for RGB thermal correction!');
    end
    uvMap3 = params.rgbTmat\[uvMapUndist ones(size(uvMapUndist,1),1)]';
    uvMapUndist = uvMap3(1:2,:)';
end
uvErr = ptsRGB - uvMapUndist;
uvRMS = sqrt(nanmean(nansum(uvErr.^2,2)));

if plotFlag
    figure;
    subplot(121);
    imagesc(frame.i);
    title('IR')
    hold on
    plot(ptsDepth(:,1),ptsDepth(:,2),'r*');
    subplot(122);
    imagesc(frame.yuy2);
    hold on
    plot(ptsRGB(:,1),ptsRGB(:,2),'og');
    plot(uvMapUndist(:,1),uvMapUndist(:,2),'r*');
    title(sprintf('RGB - RMS Err = %.2fpix',uvRMS))
    legend({'RGB Corners';'Projected Corners'});
end

end