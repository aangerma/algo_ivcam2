function frames = convertBytesToFrames(frameBytes, frameSize, rgbFrameSize, doAverage)
if ~exist('doAverage', 'var')
    doAverage = false;
end
frames = struct;
if ~iscell(frameBytes)
    frameBytes = {frameBytes}; % make single pose
end
for iPose = 1:length(frameBytes)
    if isfield(frameBytes{iPose}, 'i')
        frames(iPose).i = convertBytesToFramesSingleType(frameBytes{iPose}.i, frameSize, 'uint8', doAverage);
    end
    if isfield(frameBytes{iPose}, 'z')
        frames(iPose).z = convertBytesToFramesSingleType(frameBytes{iPose}.z, frameSize, 'uint16', doAverage);
    end
    if isfield(frameBytes{iPose}, 'yuy2')
        frames(iPose).yuy2 = convertBytesToFramesSingleType(frameBytes{iPose}.yuy2, rgbFrameSize, 'uint16', doAverage);
    end
end
end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function frames = convertBytesToFramesSingleType(bytesMat, frameSize, frameClass, doAverage)
% frame size handling
[nFrames, nPixels] = size(bytesMat); % for uint8
if strcmp(frameClass, 'uint16')
    nPixels = nPixels/2;
end
assert(nPixels == prod(frameSize), 'BIN data size incompatible with frame size')
% bin data conversion
frames = zeros(frameSize(1), frameSize(2), nFrames, frameClass);
for iFrame = 1:nFrames
    frames(:,:,iFrame) = reshape(typecast(bytesMat(iFrame,:), frameClass), frameSize(1), frameSize(2));
end
if doAverage
    frames = Calibration.aux.average_images(frames);
end
end
