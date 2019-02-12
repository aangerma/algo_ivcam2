%version = 1.0;
%outputFolder = sprintf('\\\\ger\\ec\\proj\\ha\\RSG\\SA_3DCam\\Algorithm\\Releases\\IVCAM2.0\\MaxRange2Apd\\%4.2f\\',version);
outputFolder = '\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Share\MaxDist2Vapd_V3';
if exist(outputFolder,'dir')
    answer = questdlg('Folder Already exist, Override?', ...
        'Folder Exists', ...
        'Yes','No','No');
    % Handle response
    switch answer
        case 'No'
            return;
    end
end
mkdirSafe(outputFolder);
releaseFunctionCode('maxRange2Apd.m',outputFolder);
releaseFunctionCode( fullfile(ivcam2root,'+Pipe','bootCalcs.m'),outputFolder);

copyfile('maxRangeToVapdConfig.xml',outputFolder);
extraIv2Copy = {
    '+Pipe\tables\'...
    '+Calibration\targets\'...
    '+Calibration\initConfigCalib\'...
    '+Calibration\releaseConfigCalib\'...
    '@HWinterface\presetScripts\'...
    '@HWinterface\IVCam20Device\'};
cellfun(@(x)(copyfile(fullfile(ivcam2root,x),fullfile(outputFolder,x))),extraIv2Copy);

extraCommonCopy = {
    'Common\@FirmwareBase\'};
cellfun(@(x)(copyfile(fullfile(commonRoot,x),fullfile(outputFolder,x))),extraCommonCopy);

