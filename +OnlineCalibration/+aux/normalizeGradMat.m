function [gradNormMat] = normalizeGradMat(camerasParams,frames)
% dividing the grad matrix by the output of the function will make it so a
% step of each variable will move the locations in the image by a similar
% amount of pixels
gradNormMat = zeros(3,4);
dist = 1500;
Z = single(camerasParams.zMaxSubMM)*ones(size(frames.z(:,:,1)))*dist;
V = OnlineCalibration.aux.z2vertices(Z,ones(numel(Z),1),camerasParams);
  
for i = 1:12
    i
    gradNormMat(i) = findGradFactor(V,camerasParams,i);
end

end

function gf = findGradFactor(V,camerasParams,i)

clear e step
desiredStep = 0.1;
acc = 0.001;
diff = 0;

uvMapOrig = OnlineCalibration.aux.projectVToRGB(V,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
stepLow = 0;
stepHigh = 1000;
step(1:2) = [0,1000];
rgbPmat = camerasParams.rgbPmat;
rgbPmat(i) = rgbPmat(i) + step(end);
uv = OnlineCalibration.aux.projectVToRGB(V,rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
e(1:2) = [0,mean(sum((uv-uvMapOrig).^2,2))];

while abs(e(end)-desiredStep) > acc
    
    step(end+1) = 0.5*(stepLow + stepHigh);
    rgbPmat = camerasParams.rgbPmat;
    rgbPmat(i) = rgbPmat(i) + step(end);
    uv = OnlineCalibration.aux.projectVToRGB(V,rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);
    e(end+1) = mean(sum((uv-uvMapOrig).^2,2));
    
    if e(end) > desiredStep
        stepHigh = step(end);
    else
        stepLow = step(end);
    end
    
    
    abs(e(end)-desiredStep);
end
gf = step(end);
end