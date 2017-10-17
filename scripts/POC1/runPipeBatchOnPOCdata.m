function runPipeBatchOnPOCdata(baseDir)
if(~exist('baseDir','var'))
    % baseDir = '\\invcam322\Ohad\data\lidar\EXP\regression\Rchart\';
    % baseDir = '\\invcam322\Ohad\data\lidar\EXP\regression\horseD\';
    % baseDir = '\\invcam322\Ohad\data\lidar\EXP\20151224\depthVGA\';
    % baseDir = '\\invcam322\Ohad\data\lidar\EXP\20151231\depth2\';
    % baseDir = '\\invcam322\Ohad\data\lidar\EXP\20160208\';
%      baseDir = 'd:\Ohad\data\lidar\EXP\regression\planes\32\';
     baseDir = 'd:\Ohad\data\lidar\EXP\20160811\8xtargets\32\';
     baseDir = 'd:\ohad\data\lidar\EXP\20161019\';
end


ivsfns = io.POC.scopeFolder2ivs(baseDir,'POC3');

for i=1:length(ivsfns)
    pipeOutData=Pipe.autopipe(ivsfns{i},'viewResults',true);
end
end


