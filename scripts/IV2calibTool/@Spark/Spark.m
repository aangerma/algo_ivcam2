classdef Spark<handle
    properties (Access=private)
        m_gen
        m_DUTnum
        m_outputFolder
        
    end
     methods (Static, Access = private)
           function s = sprivMakeProp(prop,value)
               if(isnumeric(value))
                   value=num2str(value);
               end
               s=RealSense.Tools.SparkGenerator.API.SparkProperty(prop,value);
           end
     end
    
    methods (Access=public)
        
        
        
        
        function obj = Spark(operatorName,workOrder,outputFolder)
            if(~exist('outputFolder','var'))
                outputFolder='c:\temp';
            end
            obj.m_outputFolder=outputFolder;
            
            
            p = fullfile(fileparts(mfilename('fullpath')),filesep);
            dnet = dirFiles(p,'*.dll',false);
            dnet=strcat(p,dnet);
            cellfun(@(x) NET.addAssembly(x),dnet,'uni',0);
            %%
            obj.m_gen=RealSense.Tools.SparkGenerator.API.SparkGeneratorAPI('TestType',RealSense.Tools.SparkGenerator.API.ProductName.IVCAM_20,RealSense.Tools.SparkGenerator.API.TestMode.ATP);
            %%
            obj.m_gen.StartSession(operatorName,workOrder);
            obj.m_DUTnum=[];
            
        end
        
        function setOutputFolder(obj,fldr)
            obj.m_outputFolder=fldr;
        end
        
        function delete(obj)
            mkdirSafe(obj.m_outputFolder);
            obj.m_gen.EndSession(obj.m_outputFolder);
        end
        
        function num=startDUTsession(obj,sessName,setAsCurrent)
            if(~exist('setAsCurrent','var'))
                setAsCurrent=true;
            end
            dts=obj.m_gen.CreateDutTestSession(sessName);
            num = dts.DutIndex;
            obj.m_DUTnum(end+1)=num;
            if(setAsCurrent)
                obj.setCurrentDUT(num);
            end
        end
        
        function endDUTsession(obj,num,hasTesterFailure)
            if(~exist('num','var') || isempty(num) || num<=0)
                if(~isempty(obj.m_DUTnum))
                    num=obj.m_DUTnum(end);
                else
                    return;
                end
            end
            if(~exist('hasTesterFailure','var'))
                hasTesterFailure=false;
            end
            
            dts = obj.m_gen.GetDutTestSession(num);
            dts.EndSession(hasTesterFailure);
            obj.m_DUTnum = setxor(obj.m_DUTnum,num);
        end
        
        function setCurrentDUT(obj,num)
            obj.m_DUTnum=circshift(obj.m_DUTnum,-find(obj.m_DUTnum==num,1));
        end
       
         function addTestProperty(obj,prop,value)
            obj.m_gen.AddPropertiesToTestSession(Spark.sprivMakeProp(prop,value));
        end
        
        function addDTSproperty(obj,prop,value)
            dts = obj.m_gen.GetDutTestSession(obj.m_DUTnum(end));
            dts.AddProperties(Spark.sprivMakeProp(prop,value));
        end
        
        function addDUTproperty(obj,prop,value)
            dts = obj.m_gen.GetDutTestSession(obj.m_DUTnum(end));
            dts.AddDutProperties(Spark.sprivMakeProp(prop,value));
        end
        
        function AddMetrics(obj,metricName,val,minval,maxval,isMandatory)
            dts = obj.m_gen.GetDutTestSession(obj.m_DUTnum(end));
            dts.AddMetrics(RealSense.Tools.SparkGenerator.API.SparkMetric(metricName, isMandatory,minval,maxval,val));
        end
        
        function disp(obj)
            fprintf('open sessions:\n');
            if(isempty(obj.m_DUTnum))
                fprintf('(none)\n');
            else
                for i=1:length(obj.m_DUTnum)
                    dts = obj.m_gen.GetDutTestSession(obj.m_DUTnum(i));
                    fprintf('%2d. %s\n',dts.DutIndex,char(dts.DutSerialNumber));
                end
            end
        end
        
        
    end
    
    
    
end