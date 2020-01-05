function [ tpsUndistModel ] = createTpsUndistModel( points1,points2,runParams )
%{ 
This function recieves:
points1 - a 2xN points array. First col should represent a data point 
points2 - a 2xN values array - the correct values for the data

%}
% Test code
% [xx,yy] = meshgrid(0:20:639,0:20:479);
% rr = xx + yy;
% points1 = [xx(:),yy(:)]';
% points2 = [xx(:),yy(:)]' + rr(:)'/600;


if ~exist('runParams','var')
    runParams = [];
end
% fprintf('Calculating Undist TPS model, be patience (should take around 2 minutes) ... ');
tpsUndistModel = tpaps(points1,points2);
% fprintf('Done\n');
% avals = fnval(st,points1);

if ~isempty(runParams) && isfield(runParams, 'outputFolder')
    dirname = fullfile(runParams.outputFolder,'AlgoInternal');
    mkdirSafe(dirname)
    save(fullfile(dirname,'tpsUndistModel.mat'),'tpsUndistModel');
end
% quiver(points1(1,:),points1(2,:),points2(1,:)-points1(1,:),points2(2,:)-points1(2,:))
% quiver(points1(1,:),points1(2,:),points2(1,:)-avals(1,:),points2(2,:)-avals(2,:))
% histogram(points2(1,:)-points1(1,:))
% histogram(points2(1,:)-avals(1,:))


end

