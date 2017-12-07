% Concrete singleton implementation
classdef ArrayStream <handle
    
    properties (Access=private)
        arr
        ptr;
        
        
    end
    
   
    
    
    %% public
    methods (Access=public)
        
        
        
        
        function obj = ArrayStream(arr)
           obj.arr = arr;
           obj.ptr=1;
        end
        
        function n = bytesRemain(obj)
            n = length(obj.arr)-obj.ptr+1;
            
        end
        
        function [data,ok] = get(obj,numBytes2read)
            data=[];
            if(obj.bytesRemain()<numBytes2read)
                ok=false;
                return;
            end
            data = obj.arr((0:numBytes2read-1)+obj.ptr);
            obj.ptr = obj.ptr+numBytes2read;
            ok = true;
        end
        
        
    end
    
end

