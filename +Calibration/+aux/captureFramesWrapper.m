function frameBytes = captureFramesWrapper(hw, type, nFrames)
% preparations
frameBytes = struct;
if (strcmp(type, 'ALT_IR'))
    type = 'I';
end
% capturing
if contains(type, 'rgb')
    imRgb = hw.getColorFrameRAW(1);
end
imDepth = hw.getFrame(nFrames, false);
% data streaming
if contains(type, 'I')
    for iFrame = 1:nFrames
        frameBytes.i(iFrame,:) = imDepth(iFrame).i(:);
    end
end
if contains(type, 'Z')
    for iFrame = 1:nFrames
        frameBytes.z(iFrame,:) = typecast(imDepth(iFrame).z(:), 'uint8');
    end
end
if contains(type, 'rgb')
    frameBytes.yuy2(1,:) = typecast(imRgb.color(:), 'uint8');
end

end

