function frame=privGetSingleFrame(obj)
    %get single frame
    imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
    % get depth
    imageObj = imageCollection.Images.Item(0);
    dImByte = imageObj.Item(0).Data;
    frame.z = typecast(cast(dImByte,'uint8'),'uint16');
    frame.z = reshape(frame.z(1:end-regs.PCKR.padding),regs.GNRL.imgVsize,regs.GNRL.imgHsize);
    % get IR
    imageObj = imageCollection.Images.Item(1);
    iImByte = imageObj.Item(0).Data;
    frame.i = cast(iImByte,'uint8');
    frame.i = reshape(frame.i(1:end-regs.PCKR.padding),regs.GNRL.imgVsize,regs.GNRL.imgHsize);
    
    % get C
    imageObj = imageCollection.Images.Item(2);
    cImByte = imageObj.Item(0).Data;
    cIm8 = cast(cImByte,'uint8');
    frame.c = bitand(cIm8(:),uint8(15))';
    frame.c = reshape(frame.c(1:end-regs.PCKR.padding),regs.GNRL.imgVsize,regs.GNRL.imgHsize);
%             imageObj = imageCollection.Images.Item(2);
%             cImByte = imageObj.Item(0).Data;
%             cIm8 = cast(cImByte,'uint8');
%             frame.c=reshape([ bitand(cIm8(:),uint8(15)) bitshift(cIm8(:),-4)]',size(frame.i));
end