function [warper] = fetchDsmWarper(serial,res,scaleChangeInX,scaleChangeInY)

persistent  DSMWarpers;
persistent  DSMWarpersKeys;
scaleChangeValues = linspace(-2,2,21);

% Find closest X and Y scale factors
[~,mIx] = min(abs(scaleChangeValues-scaleChangeInX));
[~,mIy] = min(abs(scaleChangeValues-scaleChangeInY));
scaleX = num2str(scaleChangeValues(mIx));
scaleY = num2str(scaleChangeValues(mIy));


currentKey = sprintf('%s\\DSMWrapper_%dx%d_scaleChangeX_%s_scaleChangeY_%s_.bin',serial,res(1),res(2),scaleX,scaleY);
boolKeyLocation = strcmp(DSMWarpersKeys,currentKey);
if any(boolKeyLocation)
    warper = DSMWarpers{boolKeyLocation};
    return;
else
    frameWarpersHeadDir = 'X:\IVCAM2_calibration _testing\unitsDSMWrappers';
    warperPath = fullfile(frameWarpersHeadDir,currentKey);
    if isfile(warperPath)
        warper = OnlineCalibration.Aug.FrameDsmWarper;
        warper = warper.loadDsmWarp(warperPath,res);
        DSMWarpers{numel(DSMWarpers)+1} = warper;
        DSMWarpersKeys{numel(DSMWarpersKeys)+1} = currentKey;
    else
        error('No waarper match the path: %s\n',warperPath);
    end
end



end

