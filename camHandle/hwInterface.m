% Concrete singleton implementation
classdef hwInterface <handle
    
    properties (Access=private)
        m_cam;
        m_fw;
    end
    
    
    
    
    
    methods (Static=true, Access=private)
        %
    end
    
    methods (Access=private)
        %
    end
    
    methods (Access=public)
        
        function newObj = hwInterface(fw)
            if(nargin==0 || ~isa(fw,'Firmware'))
                error('hwInterface c-tor must be initialized with valid Firmware object');
            end
            
            newObj.m_fw = fw;
                        newObj.m_cam = camInterface();
%             newObj.m_cam = 1;
        end
        
        
        
        
        function read(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            
            meta = obj.m_fw.genMWDcmd(regTokens);
            meta = str2cell(meta,newline);
            meta(end) = [];%only newLine
            for i=1:length(meta)
                str = strsplit(meta{i});
                res = obj.m_cam.cmd(['mrd ' str{2} ' ' str{3}]);
                res = res(end-7:end);
                disp([str{5}(3:end) ' = ' res]);
            end
        end
        
        
        function write(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            meta = obj.m_fw.genMWDcmd(regTokens);
            meta = str2cell(meta,newline);
            meta(end) = [];%only newLine
            for i=1:length(meta)
                str = strsplit(meta{i});
                obj.m_cam.cmd(['mwd ' str{2} ' ' str{3} ' ' str{4}]);
            end
            
            obj.m_cam.cmd('mwd a00b01f0 a00b01f4 8');%shadow update
            
        end
        
        function frame = getFrame(obj)
            frame = obj.m_cam.getFrame();
        end
        
        
    end
end



