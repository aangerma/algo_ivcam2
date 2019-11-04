function frames = convertBinDataToFrames(binData, frameSize, doAverage, cameraType)
if ~exist('doAverage', 'var')
    doAverage = false;
end
if exist('cameraType', 'var') && strcmp(cameraType, 'rgb') % RGB camera
    if iscell(binData) % several poses
        frames = cell;
        for iPose = 1:length(binData)
            frames{iPose} = convertBinDataToFramesSingleType(binData{iPose}, frameSize, 'uint16', doAverage);
            frames{iPose} = double(bitand(frames{iPose}, 255));
        end
    else % single pose
        frames = convertBinDataToFramesSingleType(binData, frameSize, 'uint16', false);
        frames = double(bitand(frames, 255));
    end
else % depth camera (default)
    frames = struct;
    if iscell(binData) % several poses
        for iPose = 1:length(binData)
            if isfield(binData{iPose}, 'i')
                frames(iPose).i = convertBinDataToFramesSingleType(binData{iPose}.i, frameSize, 'uint8', doAverage);
            end
            if isfield(binData{iPose}, 'z')
                frames(iPose).z = convertBinDataToFramesSingleType(binData{iPose}.z, frameSize, 'uint16', doAverage);
            end
        end
    else % single pose
        if isfield(binData, 'i')
            frames.i = convertBinDataToFramesSingleType(binData.i, frameSize, 'uint8', false);
        end
        if isfield(binData, 'z')
            frames.z = convertBinDataToFramesSingleType(binData.z, frameSize, 'uint16', false);
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function frames = convertBinDataToFramesSingleType(binMat, frameSize, frameClass, doAverage)
% frame size handling
[nFrames, nPixels] = size(binMat); % for uint8
if strcmp(frameClass, 'uint16')
    nPixels = nPixels/2;
end
assert(nPixels == prod(frameSize), 'BIN data size incompatible with frame size')
% bin data conversion
frames = zeros(frameSize(1), frameSize(2), nFrames, frameClass);
for iFrame = 1:nFrames
    frames(:,:,iFrame) = reshape(typecast(binMat(iFrame,:), frameClass), frameSize(1), frameSize(2));
end
if doAverage
    frames = Calibration.aux.average_images(frames);
end
end
