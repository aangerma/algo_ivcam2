classdef Firmware < FirmwareBase
        
    properties (Access=private)
        m_presetScripts;
    end
    
    
    
    methods (Access=private)
          function privLoadPresetScripts(obj)
            scriptsfldr=fullfile(fileparts(mfilename('fullpath')),'presetScripts');
            if(exist(scriptsfldr,'dir'))
            fns=dirFiles(scriptsfldr,'*.txt',false);
            keys = cellfun(@(x) x(1:end-4),fns,'uni',0);
             vals = cellfun(@(x) fullfile(scriptsfldr,x),fns,'uni',0);
            else
                keys={};
                vals={};
            end
            obj.m_presetScripts=containers.Map(keys,vals);
          end
    end
    methods (Access=public)
        
        writeFirmwareFiles(obj,outputFldr);
            
        function obj = Firmware()
        
            fwFolder = fileparts(fileparts(mfilename('fullpath')));
            tablesFolder = [fwFolder filesep '+Pipe' filesep 'tables'];
            
            obj@FirmwareBase(tablesFolder, @Pipe.bootCalcs);
             obj.privLoadPresetScripts();
        end
        
                
        function txt=getPresetScript(obj,scriptname)
            txt=obj.m_presetScripts(scriptname);
        end
        
      
    end
    
end

