function [ vPreTps ] = inverseUndistByTPSModel( vPostTps, tpsModel, runParams)
%INVERSEUNDISTBYTPSMODEL applies the inverse TPS model on x/z and y/z. Returns a
%normalized unit vecor. Assumes v to be an Nx3 XYZ vector. tpsModel should
%be generated by the function Calibration.Undist.createTpsUndistModel. 
% In case tpsModel is empty, we can load a saved model from
% runParams.outputFolder.
if isempty(tpsModel) && ~exist('runParams','var')
    vPreTps = vPostTps;
    return;
end
if isempty(tpsModel)
   load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); 
end

% Generate LUT
paddingFactor = 0.05;
tanLims = max(abs(tpsModel.centers),[],2)*(1+paddingFactor);
nPts = 100; % excessive, although not time-consuming
[tanyGridOut, tanxGridOut] = ndgrid(linspace(-tanLims(2), tanLims(2), nPts), linspace(-tanLims(1), tanLims(1), nPts));
tanxyGridIn = fnval(tpsModel, [tanxGridOut(:), tanyGridOut(:)]');
xInterpolant = scatteredInterpolant(tanxyGridIn(1,:)', tanxyGridIn(2,:)', tanxGridOut(:), 'linear');
yInterpolant = scatteredInterpolant(tanxyGridIn(1,:)', tanxyGridIn(2,:)', tanyGridOut(:), 'linear');

% Use LUT
nPoints = size(vPostTps,1);
tanVec = double(vPostTps(:,1:2)./vPostTps(:,3))';
preTpsTanX = xInterpolant(tanVec(1,:), tanVec(2,:));
preTpsTanY = yInterpolant(tanVec(1,:), tanVec(2,:));
preTpsTanVec = [preTpsTanX; preTpsTanY];
vPreTps =  [preTpsTanVec',ones(nPoints,1)];
vPreTps = normr(vPreTps);

end
