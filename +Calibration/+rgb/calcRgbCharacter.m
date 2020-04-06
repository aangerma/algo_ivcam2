function [results] = calcRgbCharacter(rgbData, params)
K = du.math.getK(rgbData.color.Kn,double(params.RGBImageSize));
[results.hFov, results.vFov] = du.math.calcDistortedFov(K,rgbData.color.d,params.RGBImageSize);
[results.rad,results.tang] = du.math.dist2Characterisation(rgbData.color.d,[params.distFromPP4distortion1,params.distFromPP4distortion2]);
results.rx = ocv.Rodrigues(double(rgbData.extrinsics.r)).*180./pi();
results.fx = K(1);
results.fy = K(5);
results.px = K(7);
results.py = K(8);
end

