function [DSMWarpers,DSMWarpersKeys,scaleChangeValues] = loadDsmWarpers()

persistent  DSMWarpersP;
persistent  DSMWarpersKeysP;
persistent  scaleChangeValuesP;

if ~isempty(DSMWarpersP) && ~isempty(DSMWarpersKeysP) && ~isempty(scaleChangeValuesP)
    DSMWarpers = DSMWarpersP;
    DSMWarpersKeys = DSMWarpersKeysP;
    scaleChangeValues = scaleChangeValuesP;
    return; 
end

fprintf('Loading DSM Warpers, be patient...\n');
jointDSMWrappersFn = 'X:\IVCAM2_calibration _testing\unitsDSMWrappers\jointDSMWrappers.mat';
if isfile(jointDSMWrappersFn)
    x = load(jointDSMWrappersFn);
    DSMWarpers = x.DSMWarpers;
    DSMWarpersKeys = x.DSMWarpersKeys;
    scaleChangeValues = x.scaleChangeValues;
else
    scaleChangeValuesP = linspace(-2,2,21);
    ind = 0;
    warpersDir = 'X:\IVCAM2_calibration _testing\unitsDSMWrappers';
    unitDirs = dir(fullfile(warpersDir,'F*'));
    for i = 1:numel(unitDirs)
        warpersFiles = dir(fullfile(warpersDir,unitDirs(i).name,'DSMWrapper*'));
        for k = 1:numel(warpersFiles)
            ind = ind + 1;
            splittedName = split(warpersFiles(k).name,'_');
%             scaleChangeX = str2num(splittedName{4});
%             scaleChangeY = str2num(splittedName{6});
            res = sscanf(splittedName{2}, '%dx%d')';
            DSMWarpersKeysP{ind,1} = strjoin({unitDirs(i).name;num2str(res(1));num2str(res(2));splittedName{4};splittedName{6}},'_');
            warpper = OnlineCalibration.Aug.FrameDsmWarper;
            warpper = warpper.loadDsmWarp(fullfile(warpersDir,unitDirs(i).name,warpersFiles(k).name),res);
            DSMWarpersP{ind} = warpper;
        end
        
    end
    DSMWarpers = DSMWarpersP;
    DSMWarpersKeys = DSMWarpersKeysP;
    scaleChangeValues = scaleChangeValuesP;
    save(jointDSMWrappersFn,'DSMWarpers','DSMWarpersKeys','scaleChangeValues');
    


end