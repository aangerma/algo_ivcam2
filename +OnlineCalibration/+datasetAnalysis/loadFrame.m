function [frame,apdGain] = loadFrame(framePath,dbType)
apdGain = 0;
global runParams;
switch dbType
    case 'iq'
        load(fullfile(framePath,'InputData.mat'),'frame');
        try
            mdFile = dir(fullfile(framePath,'../../**/md.json'));
            md = loadjson(fullfile(mdFile.folder,mdFile.name));
            apdGain = 18*strcmp(md.preset,'low_ambient') + 9*(1-strcmp(md.preset,'low_ambient'));
        catch
            fprintf('Could not find md file for scene:\n %s\n',framePath);
        end
    case 'robot'
        load(framePath,'frame');
    case 'dataCollection'
        runParams.loadSingleScene = 1;
        frame = OnlineCalibration.aux.loadZIRGBFrames(framePath,[]);
        frame.yuy2Prev = frame.yuy2(:,:,1);
        frame.yuy2 = frame.yuy2(:,:,2);
    case 'dataCollectionAged'
        frame = OnlineCalibration.aux.loadZIRGBFrames(framePath,[]);
        frame.yuy2Prev = frame.yuy2(:,:,1);
        frame.yuy2 = frame.yuy2(:,:,2);
    otherwise
        error(['No such dats base: ' dbType]);
end
frame.yuy2FromLastSuccess = zeros(size(frame.yuy2));

end