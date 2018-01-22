% Concrete singleton implementation
classdef HWinterface <handle
    
    properties (Access=private)
        m_dotnetcam;
        m_fw;
    end
    
    
    
    
    
    methods (Static=true, Access=private)
        %
    end
    
    methods (Access=private)
        privInitCam(obj);
        privConfigureStream(obj);
        
        function res = cmd(obj,str)
            sysstr = System.String(str);
            result = obj.m_dotnetcam.HwFacade.CommandsService.Send(sysstr);
            if(~result.IsCompletedOk)
                error(char(result.ErrorMessage))
            end
            res = char(result.ResultFormatted);
        end
        
    end
    
    
    
    methods (Access=public)
        
        function delete(obj)
            obj.m_dotnetcam.Close();
        end
        
        
        
        
        
        function obj = HWinterface(fw)
            if(nargin==0)
                fw = Firmware;
            end
            
            obj.m_fw = fw;
            obj.privInitCam();
            obj.privConfigureStream();
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
                res = obj.cmd(['mrd ' str{2} ' ' str{3}]);
                res = res(end-7:end);
                disp([str{5}(3:end) ' = ' res]);
            end
        end
        
        
        
        
        
        
        function [regs,luts]=write(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            [regs,luts]=obj.m_fw.get();%force bootcalcs
            meta = obj.m_fw.genMWDcmd(regTokens);
            meta = str2cell(meta,newline);
            meta(end) = [];%only newLine
            for i=1:length(meta)
                str = strsplit(meta{i});
                obj.cmd(['mwd ' str{2} ' ' str{3} ' ' str{4}]);
            end
            
            obj.cmd('mwd a00d01f4 a00d01f8 000001f8');%shadow update
            
        end
        
       
        
        
        
        
        
        function frame = getFrame(obj)
            imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
            % get depth
            imageObj = imageCollection.Images.Item(0);
            dImByte = imageObj.Item(0).Data;
            frame.z = reshape(typecast(cast(dImByte,'uint8'),'uint16'),480,640);
            
            % get IR
            imageObj = imageCollection.Images.Item(1);
            iImByte = imageObj.Item(0).Data;
            frame.i = reshape(cast(iImByte,'uint8'),480,640);
            
            % get C
            imageObj = imageCollection.Images.Item(2);
            cImByte = imageObj.Item(0).Data;
            cIm8 = cast(cImByte,'uint8');
            cIm8cell = num2cell(cIm8);
            t = cellfun(@(x) [x/2^4; mod(x,2^4)],cIm8cell,'uni',0);
            tt = cell2mat(t);
            tt = tt(:);
            frame.c = reshape(tt,480,640);
            
            if(0)
                %%
                figure(2525232);clf;%#ok
                tabplot;imagesc(frame.z);
                tabplot;imagesc(frame.i);
                tabplot;imagesc(frame.c);
            end
        end
        
        
        
        
        function stopStream(obj)
            obj.m_dotnetcam.Close();
            fn = fullfile(fileparts(mfilename('fullpath')),'IVCam20Scripts','SW_Reset.txt');
            obj.runScript(fn)
        end
        
        
        
        
        function restartStream(obj)
            fn = fullfile(fileparts(mfilename('fullpath')),'IVCam20Scripts','Restart_ma_pipe.txt');
            obj.runScript(fn)
            obj.privConfigureStream();
        end
        
        
        
        
        function runScript(obj,fn)
%                      sysstr = System.String(fn);
            result = obj.m_dotnetcam.HwFacade.CommandsService.SendScript(fn);
%             if(~result.IsCompletedOk)
%                 error(char(result.ErrorMessage))
%             end
%             res = char(result.ResultFormatted);
        end
    end
end



