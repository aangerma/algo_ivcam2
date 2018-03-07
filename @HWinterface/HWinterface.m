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
        
        
        function txt=getPresetScript(obj,scriptname)
            txt=obj.m_fw.getPresetScript(scriptname);
        end
        
        function read(obj,regTokens)
            if(~exist('regTokens','var'))
                regTokens=[];
            end           
            
            meta = obj.m_fw.genMWDcmd(regTokens);
            meta = str2cell(meta,newline);
            meta(end) = [];%only newLine
%             regStruct=[];
            for i=1:length(meta)
                str = strsplit(meta{i});
                res = obj.cmd(['mrd ' str{2} ' ' str{3}]);
                res = res(end-7:end);
%                 regStruct.(a(1).algoBlock).(a(1).algoName)=uint32(hex2dec(res));
                disp([res ' //' str{6}]);
            end
%             obj.m_fw.setRegs(regStruct);
        end
        
        function setReg(obj,regName,regVal)
            obj.m_fw.setRegs(regName,regVal);
            meta = obj.m_fw.genMWDcmd(regName);
            obj.cmd(meta);
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
            
            obj.shadowUpdate()
            
        end
        
       
        
        function fw=getFirmware(obj)
            fw=obj.m_fw;
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
            frame.c=reshape([ bitand(cIm8(:),uint8(15)) bitshift(cIm8(:),-4)]',size(frame.i));
          
            
            if(0)
                %%
                figure(2525232);clf;%#ok
                tabplot;imagesc(frame.z);
                tabplot;imagesc(frame.i);
                tabplot;imagesc(frame.c);
            end
        end
        
        
        
        
        function stopStream(obj)
            obj.cmd(obj.getPresetScript('reset'));
        end
        
        function restartStream(obj)
            obj.cmd(obj.getPresetScript('restart'));
            obj.privConfigureStream();
        end
        
        function res = shadowUpdate(obj)
            res = obj.cmd('mwd a00d01f4 a00d01f8 00000fff'); % shadow update
            pause(0.1);
        end
        
 
        
        function res = runScript(obj,fn)
%                      sysstr = System.String(fn);
            res = obj.m_dotnetcam.HwFacade.CommandsService.SendScript(fn);
%             if(~res.IsCompletedOk)
%                 error(char(res.ErrorMessage))
%             end
%             res = char(res.ResultFormatted);
        end
    end
end



