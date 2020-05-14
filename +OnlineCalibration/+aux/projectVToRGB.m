function [uvMap,xin,yin,dbg] = projectVToRGB(V,rgbPmat,Krgb,rgbDistort,params)
tic;
    
uv = rgbPmat * [V,ones(size(V,1),1)]';
dbg.uvh = uv;
u = (uv(1,:)./uv(3,:))';
v = (uv(2,:)./uv(3,:))';
uvMap = [u,v];

xin = u; yin = v;

if exist('rgbDistort','var')
    uvMapUndist = du.math.distortCam(uvMap', Krgb, rgbDistort);
    uvMap = uvMapUndist';
end
if exist('params','var') && isfield(params,'rgbTfix') && params.rgbTfix
    if ~isfield(params,'rgbTmat')
        error('No matrix was given for RGB thermal correction!');
    end
    uvMap3 = params.rgbTmat\[uvMap ones(size(uvMap,1),1)]';
    uvMap = uvMap3(1:2,:)';
end
time = toc;
% fprintf('Projecting vertices to rgb image took %3.2f seconds\n',time);
end
