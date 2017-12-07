% Concrete singleton implementation
classdef BinaryStream <handle
    
    properties (Access=private)
        fns
        curfn;
        fid;
        
    end
    
    %% private
    methods (Access=private)
        
        function ok=privNextFile(obj)
            obj.fcloseSafe();
            if(isempty(obj.fns))
                ok=false;
            else
                ok=true;
            obj.curfn = strcat(obj.fns(1).folder,filesep,obj.fns(1).name);
            obj.fns = obj.fns(2:end);
            obj.fid = fopen(obj.curfn,'r');
            end
            
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
            if(~exist(inputDir,'dir'))
                error('directory %s do no exists',inputDir);
            end
            
            obj.fns = dir(fullfile(inputDir,filesep,'*.bin'));
            if(isempty(obj.fns))
                 error('no .bin files in directory %s',inputDir);
            end
            [~,o]=sort({obj.fns.name});
            obj.fns =obj.fns(o);
            obj.fid=-1;
            obj.privNextFile();
        end
        
        function n = bytesRemain(obj)
            n = sum([obj.fns.bytes]);
            curpos = ftell(obj.fid);
            fseek(obj.fid,0,'eof');
            endpos = ftell(obj.fid);
            fseek(obj.fid,curpos,'bof');
            n=n+(endpos-curpos);
            
        end
        
        function [data,ok] = get(obj,numBytes2read)  
            data=[];
            while(length(data)~=numBytes2read)
                data_ = fread( obj.fid,numBytes2read-length(data),'*uint8');
                if(isempty(data_))
                    ok=obj.privNextFile();
                    if(~ok)
                        break;
                    end
                end
                data = [data;data_]; %#ok;
            end
            
            ok = length(data)==numBytes2read;
        end
        
        function debugStruct = getDebugStruct(obj)
            debugStruct.curfn = obj.curfn;
            debugStruct.fid = obj.fid;
            debugStruct.ptr = ftell(obj.fid);
            debugStruct.ptrHex = dec2hex(debugStruct.ptr);
        end
        
    end
    
end

