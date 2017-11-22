% Concrete singleton implementation
classdef BinaryStream <handle
    
    properties (Access=private)
        fns
        curfn;
        fid;
        
    end
    
    %% private
    methods (Access=private)
        
        function obj=privNextFile(obj)
            obj.fcloseSafe();
            obj.curfn = obj.fns{1};
            obj.fns = obj.fns(2:end);
            obj.fid = fopen(obj.curfn,'r');
            
        end
    end
    
    
    %% public
    methods (Access=public)
        
        function obj =fcloseSafe(obj)
            if(ishandle(obj.fid))
                fclose(obj.fid);
            end
        end
        
        function str=curFile(obj)
            str=obj.curfn;
        end
        
        function obj = BinaryStream(inputDir)
            obj.fns = sort(dirFiles(inputDir,'Frame_*.bin'));
            obj.fid=-1;
            obj.privNextFile();
        end
        
        function data = get(obj,numBytes2read)  
            data=[];
            while(length(data)~=numBytes2read)
                data_ = fread( obj.fid,numBytes2read-length(data),'*uint8');
                if(isempty(data_))
                    obj.privNextFile();
                end
                data = [data;data_]; %#ok;
            end
        end
        
        function debugStruct = getDebugStruct(obj)
            debugStruct.curfn = obj.curfn;
            debugStruct.fid = obj.fid;
            debugStruct.ptr = ftell(obj.fid);
            debugStruct.ptrHex = dec2hex(debugStruct.ptr);
        end
        
    end
    
end

