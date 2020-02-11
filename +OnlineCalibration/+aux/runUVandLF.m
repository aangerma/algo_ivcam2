function [results,dbg] = runUVandLF( frames, params)

frame.z = frames.z(:,:,1);
frame.i = frames.i(:,:,1);
frame.rgbI = frames.yuy2(:,:,1);


[~, resultsUvMap,dbg] = Validation.metrics.geomReprojectErrorUV(frame, params);
pts = cat(3,dbg.cornersRGB(:,:,1),dbg.cornersRGB(:,:,2),zeros(size(dbg.cornersRGB,1),size(dbg.cornersRGB,2)));
pts = CBTools.slimNans(pts);
if isfield(params,'rgbDistort')
    invd = du.math.fitInverseDist(params.Krgbn,params.rgbDistort);
    pixsUndist = du.math.distortCam(reshape(pts(:,:,1:2),[],2)', params.Krgb, invd);
    ptsUndist = cat(3,reshape(pixsUndist',size(pts,1),size(pts,2),[]),pts(:,:,3));
    pts = ptsUndist;
end
end