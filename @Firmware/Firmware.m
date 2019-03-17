classdef Firmware < FirmwareBase
        

    

    methods (Access=public)
        
        writeFirmwareFiles(obj,outputFldr,oldVersion);
        writeAlgoThermalBin(obj,fname);
        [EPROMtable,Configtable] = generateTablesForFw(obj,outputFldr);
        fns=writeLUTbin(obj,d,fn,oneBaseCount); 
        
        function obj = Firmware()
        
            fwFolder = fileparts(fileparts(mfilename('fullpath')));
            tablesFolder = [fwFolder filesep '+Pipe' filesep 'tables'];
            obj@FirmwareBase(tablesFolder, @Pipe.bootCalcs);

        end
        
                
        
      
    end
    
end

