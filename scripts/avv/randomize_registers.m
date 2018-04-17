function randomize_registers(filePath, regsRandomList)
    fw = Firmware
    fw.randomize(filePath,regsRandomList)
    fw.writeUpdated(filePath)
end

