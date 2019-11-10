function frameBytes = captureFramesWrapper(hw, type, nFrames)
% preparations
frameBytes = struct;
if (strcmp(type, 'ALT_IR'))
    type = 'I';
end
% capturing
if contains(type, 'C')
    imRgb = hw.getColorFrameRAW(1);
end
imDepth = hw.getFrame(nFrames, false);
% data streaming
if contains(type, 'I')
    for iFrame = 1:nFrames
        frameBytes.i(iFrame,:) = uint8(imDepth(iFrame).i(:));
    end
end
if contains(type, 'Z')
    for iFrame = 1:nFrames
        frameBytes.z(iFrame,:) = uint8(typecast(imDepth(iFrame).z(:), 'uint8'));
    end
end
if contains(type, 'C')
    frameBytes.yuy2 = uint8(typecast(imRgb.color(:), 'uint8'));
end

end

