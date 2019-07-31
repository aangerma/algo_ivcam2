function [ vPostTps ] = undistByTPSModel( v,tpsModel,runParams )
%UNDISTBYTPSMODEL applies the TPS model on x/z and y/z. Retunrs a
%normalized unit vecor.
if isempty(tpsModel)
   load(fullfile(runParams.outputFolder,'AlgoInternal','tpsUndistModel.mat')); 
end

nPoints = size(v,1);
tanVec = (v(:,1:2)./v(:,3))';
postTpsTanVec = fnval(tpsModel,tanVec);
vPostTps =  [postTpsTanVec',ones(nPoints,1)];
vPostTps = normr(vPostTps);
end

