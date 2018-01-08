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
        
        function newObj = camInterface(fw)
            newObj.m_fw = fw;
            newObj.m_cam = camInterface();
        end
        
        
        
        
        function read(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            meta = obj.m_fw.getMeta(regTokens);
            add = [meta.addres];
            
            for i=1:length(add)
                res = obj.m_cam.cmd(['MRD ' add{i} add{i}+4]);
                disp([meta.regName{i} ' = ' res]);
            end
        end
        
        
        function write(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            meta = obj.m_fw.getMeta(regTokens);
            add = [meta.addres];
            
            for i=1:length(add)
                obj.m_cam.cmd(['MWR ' add{i} add{i}+4 meta.val{i}]);
            end
            
            obj.m_cam.cmd(['MWR ?????? ??????? ?' ]); %shadow update
            
        end
        
        function frame = getFrame(obj)
            frame = obj.m_cam.getFrame();
        end
        
        
    end
end



