function uvRMS = calcUVMappingErr(frame,params,plotFlag)
if ~exist('plotFlag','var')
    plotFlag = 0;
end



CB = CBTools.Checkerboard (frame.i,'expectedGridSize',params.cbGridSz); 
ptsDepth = CB.getGridPointsList;

CB = CBTools.Checkerboard (frame.yuy2,'expectedGridSize',params.cbGridSz);
ptsRGB = CB.getGridPointsList;



% Depth corners to vertices
zVals = interp2(single(frame.z)/single(params.zMaxSubMM),ptsDepth(:,1),ptsDepth(:,2));
VDepth = (pinv(params.Kdepth)*([ptsDepth-1,ones(prod(params.cbGridSz),1)]'))'.*zVals;

% Project to RGB
uv = params.rgbPmat * [VDepth ones(size(VDepth,1),1)]';
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';
uvMap = [u,v];
uvMapUndist = du.math.distortCam(uvMap', params.Krgb, params.rgbDistort)' + 1;

uvErr = ptsRGB - uvMapUndist;
uvRMS = sqrt(mean(sum(uvErr.^2,2)));

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