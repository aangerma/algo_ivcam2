function [RGBTable] = buildRGBTable(res,params,rgbCalTemperature)
    
    %definitions
    TableSize = 112;
    
    %current table version
    TableVersionMajor = uint8(floor(params.version));
    TableVersionMinor = uint8(mod(params.version*100,100));
    calibratorID = uint8(1);
    procId = uint8(0);
    %initialize the stream
    arr = zeros(1,TableSize,'uint8');
    s = Stream(arr);
    
    % header
    timestamp = uint32(now);
    [~,~,versionBytes] = AlgoCameraCalibToolVersion;
    
    s.setNext(versionBytes(1:2));
    s.setNext(calibratorID);
    s.setNext(procId);
    
    s.setNextUint32(timestamp);
    s.setNextUint16(params.RGBImageSize);
    s.setNextUint16([0 0]);
    
    %RGB intrinsic
    s.setNextSingle( res.color.Kn([1,5,7,8,4]));
    s.setNextSingle( res.color.d);
    
    %RGB extrinsic
    s.setNextSingle( res.extrinsics.r');
    s.setNextSingle( res.extrinsics.t);

    s.setNextSingle(single(rgbCalTemperature));
    
    RGBTable.data = s.flush();
    RGBTable.version = [TableVersionMajor TableVersionMinor];
end

