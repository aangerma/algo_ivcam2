function [frame] = loadFrame(framePath,dbType)
global runParams;
switch dbType
    case 'iq'
        load(fullfile(framePath,'InputData.mat'),'frame');
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