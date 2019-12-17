function thermalCorrection = getThermalCorrectionFromBin(thermalBinFile, plotFlag)

if ~exist('plotFlag', 'var')
    plotFlag = false;
end

fid = fopen(thermalBinFile, 'rb');
tableBytes = fread(fid);
fclose(fid);

tableBytesUint16            = typecast(uint8(tableBytes),'uint16');
thermalCorrection.xScale    = single(tableBytesUint16(1:5:end))/2^8;
thermalCorrection.yScale    = single(tableBytesUint16(2:5:end))/2^8;
thermalCorrection.xOffset   = single(tableBytesUint16(3:5:end))/2^8;
thermalCorrection.yOffset   = single(tableBytesUint16(4:5:end))/2^8;

tableBytesInt16             = typecast(uint8(tableBytes),'int16');
thermalCorrection.rtdOffset = single(tableBytesInt16(5:5:end))/2^8;

if plotFlag
    figure
    subplot(2,3,[1,4])
    plot(thermalCorrection.rtdOffset,'.-')
    grid on, xlabel('#bin'), ylabel('table [mm]'), title('RTD correction')
    subplot(2,3,2)
    plot(thermalCorrection.xScale,'.-')
    grid on, xlabel('#bin'), ylabel('table [1/deg]'), title('X scale')
    subplot(2,3,3)
    plot(thermalCorrection.xOffset,'.-')
    grid on, xlabel('#bin'), ylabel('table [deg]'), title('X offset')
    subplot(2,3,5)
    plot(thermalCorrection.yScale,'.-')
    grid on, xlabel('#bin'), ylabel('table [1/deg]'), title('Y scale')
    subplot(2,3,6)
    plot(thermalCorrection.yOffset,'.-')
    grid on, xlabel('#bin'), ylabel('table [deg]'), title('Y offset')
end

end




