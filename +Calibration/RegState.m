classdef RegState <handle
    properties (Access=private)
        m_dataset
        m_hw
    end
    
    methods (Access=public)
        
        
        function obj = RegState(hw)
            obj.m_hw=hw;
            obj.m_dataset=struct('name',[],'holdval',[],'setval',[]);
            obj.m_dataset=obj.m_dataset([]);
        end
        
        function obj = add(obj,regName,regVal)
            indx=find(strcmp(regName,{obj.m_dataset.name}),1);
            if(isempty(indx))
                obj.m_dataset(end+1)=struct('name',regName   ,'setval',regVal     ,'holdval',[]);
            else
                %alreay set
                obj.m_dataset(indx).setval=indx;
            end
        end
        
        function set(obj)
            %% GET OLD VALUES
            for i=1:length(obj.m_dataset)
                %if already got value, do not get it again!
                if(isempty(obj.m_dataset(i).holdval))
                    obj.m_dataset(i).holdval=obj.m_hw.read(obj.m_dataset(i).name );
                end
            end
            
            %% SET NEW VALUES
            for i=1:length(obj.m_dataset)
                obj.m_hw.setReg(obj.m_dataset(i).name    ,obj.m_dataset(i).setval,true);
            end
            obj.m_hw.shadowUpdate();
        end
        function delete(obj)
            obj.reset();
        end
        function reset(obj)
            %% SET OLD VALUES
            for i=1:length(obj.m_dataset)
                obj.m_hw.setReg(obj.m_dataset(i).name    ,obj.m_dataset(i).holdval);
            end
            obj.m_dataset=obj.m_dataset([]);
            obj.m_hw.shadowUpdate();
        end
        
        
    end
end