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
        
        function [res,val] = cmd(obj,str)
            sysstr = System.String(str);
            result = obj.m_dotnetcam.HwFacade.CommandsService.Send(sysstr);
            if(~result.IsCompletedOk)
                error(char(result.ErrorMessage))
            end
            res = char(result.ResultFormatted);
            try
                val = uint8(result.ResultRawData);
                if(length(val)==4)
                    val = typecast(val,'uint32');
                end
            catch
                val=nan;
            end
        end
        
        %destructor
        function delete(obj)
            obj.runScript(obj.getPresetScript('stopStream'));
            obj.m_dotnetcam.Close();
        end
        
        
        
        burn2device(obj,basedir,burnCalib,burnConfig);
        
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
        
        function dispRegs(obj,regTokens)
            
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            [vals,algoNames]=obj.read(regTokens);
            s=[num2cell(vals) algoNames]';
            fprintf('%08x //%s\n',s{:});
            
        end
        
        function val=writeAddr(obj,addr,val,safeWrite)
            if(~exist('safeWrite','var'))
                safeWrite=false;
            end
            if(ischar(addr))
                addr=uint32(hex2dec(addr));
            elseif(isa(addr,'uint32'))
            else
                error('addr should be either hex or uint32');
            end
            if(ischar(val))
                val=uint32(hex2dec(val));
            elseif(~isa(val,'uint32'))
                error('Value should be uint32');
            end
            
            if(~safeWrite)
                [~,val]=obj.cmd(sprintf('mwd %08x %08x %08x',addr,addr+4,val));
                return;
            end
            %safe write
            nAttempts=10;
            for i=1:nAttempts
                obj.cmd(sprintf('mwd %08x %08x %08x',addr,addr+4,val));
                pause(0.1);
                val_=obj.readAddr(addr);
                if(val==val_)
                    return;
                end
                
            end
            error('Could not write register');
        end
        
        function val=readAddr(obj,addr)
            if(ischar(addr))
                addr=uint32(hex2dec(addr));
            elseif(isa(addr,'uint32'))
            else
                error('addr should be either hex or uint32');
            end
            
            [~,val]=obj.cmd(sprintf('mrd %08x %08x',addr,addr+4));
        end
        
        function [vals,algoNames]=read(obj,regTokens)
            strOutFormat = 'mrd %08x %08x';
            if(~exist('regTokens','var'))
                regTokens=[];
            end
            
            meta = obj.m_fw.getAddrData(regTokens);
            vals = zeros(size(meta,1),1,'uint32');
            for i=1:size(meta,1)
                if(any(strcmpi(meta{i,3}(1:4),{'MTLB','FRMW','EPTG'})))
                    continue;
                end
                cmd = sprintf(strOutFormat,meta{i,1},meta{i,1}+4);
                [~,vals(i)] = obj.cmd(cmd);
                
                
            end
            algoNames=meta(:,3);
            
        end
        
        function setReg(obj,regToken,regVal,forceUpdate)
            m=obj.m_fw.getMeta(regToken);
            if(length(m)~=1)
                error('can set only one register');
            end
%             regVal_=cast(uint32(regVal),m.type);
            regVal_=cast(regVal,m.type);
            if(exist('forceUpdate','var') && forceUpdate)
                obj.m_fw.setRegs(m.regName,regVal_,'forceupdate');
            else
                obj.m_fw.setRegs(m.regName,regVal_);
            end
            meta = obj.m_fw.genMWDcmd(m.regName);
            obj.cmd(meta);
        end
        
        
        
        
        function write(obj,regName,regVal)
           
                m=obj.m_fw.getMeta(regName);
                if(length(m)~=1)
                    error('bad register name');
                end
                obj.writeAddr(uint32(m.address),regVal);
          
%                 warning('FUNCTION IS CANDIDATE FOR REMOVAL')
%                 
%                 if(~exist('regTokens','var'))
%                     regTokens=[];
%                 end
%                 [regs,luts]=obj.m_fw.get();%force bootcalcs
%                 meta = obj.m_fw.genMWDcmd(regTokens);
%                 tfn = [tempname '.txt'];
%                 fid = fopen(tfn,'w');
%                 fprintf(fid,meta);
%                 fclose(fid);
%                 obj.runScript(tfn);
%                 obj.shadowUpdate()
         
        end
        
        
        
        function fw=getFirmware(obj)
            fw=obj.m_fw;
        end
        
        
        
        function frame = getFrame(obj,n)
            if (exist('n','var') && n > 1)
                
                for i = 1:n
                    stream(i) = obj.getFrame();%#ok
                end
                meanNoZero = @(m) sum(double(m),3)./sum(m~=0,3);
                collapseM = @(x) meanNoZero(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]));
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
            if(nargin==1)
                k=obj.m_presetScripts.keys;
                k=[k;k];
                fprintf('Available scripts:\n');
                fprintf('\t-<a href="matlab:hw.runPresetScript(''%s'');">%s</a>\n',k{:});
                return;
            end
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



