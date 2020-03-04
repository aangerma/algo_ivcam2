classdef Firmware < FirmwareBase
        

    

    methods (Access=public)
        
        [EPROMtable,ConfigTable,CbufXsections,DiggGammaTable]  = generateTablesForFw(obj,outputFldr,only_Algo_Calibration_Info,skip_algo_thermal_calib,versions);
        fns = writeLUTbin(obj,d,fn,oneBaseCount); 
        [regs] = readAlgoEpromData(obj,BinData,EPROMstructure)
            
        
        function obj = Firmware(tablesFolder)
            if ~exist('tablesFolder','var')
                tablesFolder = [];
            end
            if ~exist(tablesFolder,'dir')
                fwFolder = fileparts(fileparts(mfilename('fullpath')));
                tablesFolder = [fwFolder filesep '+Pipe' filesep 'tables'];
            end
            obj@FirmwareBase(tablesFolder, @Pipe.bootCalcs);

        end
        
                
        
      
    end
    
end

