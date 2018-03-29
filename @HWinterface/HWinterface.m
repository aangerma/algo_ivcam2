% Concrete singleton implementation
classdef HWinterface <handle
    
    properties (Access=private)
        m_dotnetcam;
        m_fw;
        m_presetScripts;
    end
    
    
    
     methods ( Access=private)
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
    methods (Static=true, Access=private)
        %
    end
    
    methods (Access=private)
        privInitCam(obj);
        privConfigureStream(obj);
        
       
        
    end
    
    
    
    methods (Access=public)
        
         function res = cmd(obj,str)
            sysstr = System.String(str);
            result = obj.m_dotnetcam.HwFacade.CommandsService.Send(sysstr);
            if(~result.IsCompletedOk)
                error(char(result.ErrorMessage))
            end
            res = char(result.ResultFormatted);
         end
         
         %destructor
         function delete(obj)
            obj.runScript(obj.getPresetScript('stopStream'));
            obj.m_dotnetcam.Close();
        end
        
        
      
        burn2device(obj,basedir,burunConfiguration);
        
        function obj = HWinterface(fw)
            if(nargin==0)
                fw = Firmware;
            end
           
            obj.m_fw = fw;
            obj.privInitCam();
            obj.privConfigureStream();
            obj.privLoadPresetScripts();
        end
        
        
        function txt=getPresetScript(obj,scriptname)
            txt=obj.m_presetScripts(scriptname);
        end
        
        function disp(obj,regTokens)
            strOutFormat = 'mrd %08x %08x';
            if(~exist('regTokens','var'))
                regTokens=[];
            end           
            
            meta = obj.m_fw.getAddrData(regTokens);
            for i=1:length(meta)
                cmd = sprintf(strOutFormat,meta{i,1},meta{i,1}+1);
                res = obj.cmd(cmd);
                res = res(end-7:end);
                disp([res ' //' meta{i,3}]);
            end

        end
        
        function vals=read(obj,regTokens)
            strOutFormat = 'mrd %08x %08x';
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            meta = obj.m_fw.getAddrData(regTokens);
            vals = zeros(length(meta),1);
            for i=1:length(meta)
                cmd = sprintf(strOutFormat,meta{i,1},meta{i,1}+1);
                res = obj.cmd(cmd);
                res = res(end-7:end);
                vals(i)=uint32(hex2dec(res));
                
            end
            
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
            tfn = [tempname '.txt'];
            fid = fopen(tfn,'w');
            fprintf(fid,meta);
            fclose(fid);
            obj.runScript(tfn);
            obj.shadowUpdate()
            
        end
        
       
        
        function fw=getFirmware(obj)
            fw=obj.m_fw;
        end
        
        
        
        function frame = getFrame(obj,n)
            if(exist('n','var'))
                
                for i = 1:n
                    stream(i) = obj.getFrame();%#ok
                end
                collapseM = @(x) mean(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),3);
                frame.z=collapseM('z');
                frame.i=collapseM('i');
                frame.c=collapseM('c');
                return;
            end
            
            %get single frame
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
        
        
   

        
%         function stopStream(obj)
%             %obj.m_dotnetcam.Close();
%             obj.runPresetScript('reset');
%             % obj.cmd(obj.getPresetScript('reset'));
%         end
        
%         function restartStream(obj)
%             obj.runPresetScript('restart');
%             %obj.cmd(obj.getPresetScript('restart'));
%             %obj.privConfigureStream();
%         end
        
        function res = shadowUpdate(obj)
            res = obj.cmd('mwd a00d01f4 a00d01f8 00000fff'); % shadow update
            pause(0.1);
        end
        
        function res = runPresetScript(obj,scriptName)
             res=obj.runScript(obj.getPresetScript(scriptName));
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



