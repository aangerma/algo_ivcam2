% Concrete singleton implementation
classdef HWinterface <handle
    
    properties (Access=private)
        m_dotnetcam;
        m_fw;
        m_presetScripts;
        m_recData
        m_recfn
    end
    
    
    
    methods ( Access=private)
        
        function frame=privGetSingleFrame(obj)
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
        end
        
        function privRecFunc(obj,caller,varin,varout)
            if(~isempty(obj.m_recfn))
                obj.m_recData(end+1,:)={caller,varin,varout};
            end
        end
        
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
        
        privInitCam(obj);
        privConfigureStream(obj);
        
        function privDispFigRefresh(obj,f)
            d=obj.getFrame();
            aa(1)=subplot(121,'parent',f);
            z=double(d.z)/8;
            lims = prctile_(z(~isnan(z)),[5 95])+[0 1e-3];
            imagesc(z,'parent',aa(1),lims);
            axis(aa(1),'image');
            colorbar('SouthOutside','parent',f);
            aa(2)=subplot(122,'parent',f);
            imagesc(d.i,'parent',aa(2),[0 255]);
            axis(aa(2),'image');
            colorbar('SouthOutside','parent',f);
            colormap(gray(256))
            drawnow;
        end
        
        
        function [res,val] = privCmd(obj,str)
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
    end
    methods (Static=true, Access=private)
        %
        function sprivDispFigClose(t)
            stop(t)
            closereq();
        end
        
    end
    
    
    
    
    
    
    
    methods (Access=public)
        
        function [res,val] = cmd(obj,str)
            [res,val]=obj.privCmd(str);
            
            obj.privRecFunc('cmd',{str},{res,val});
        end
        
        %destructor
        function delete(obj)
            obj.runScript(obj.getPresetScript('stopStream'));
            obj.m_dotnetcam.Close();
            if(~isempty(obj.m_recfn))
                recData = obj.m_recData;%#ok
                save(obj.m_recfn,'recData');
            end
        end
        
        
        
        burn2device(obj,basedir,burnCalib,burnConfig);
        
        function obj = HWinterface(fw,recfn)
            if(nargin==0)
                fw = Firmware;
            end
            if(nargin<=1)
                recfn=[];
            end
            obj.m_recfn=recfn;
            obj.m_fw = fw;
            obj.privInitCam();
            obj.privConfigureStream();
            obj.privLoadPresetScripts();
            obj.m_recData={};
            obj.privRecFunc('HWinterface',{fw},{});
            
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
        
        function writeAddr(obj,addr,val,safeWrite)
            
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
                obj.privCmd(sprintf('mwd %08x %08x %08x',addr,addr+4,val));
            else
                %safe write
                nAttempts=10;
                ok=false;
                for i=1:nAttempts
                    obj.privCmd(sprintf('mwd %08x %08x %08x',addr,addr+4,val));
                    pause(0.1);
                    [~,val_]=obj.privCmd(sprintf('mrd %08x %08x',addr,addr+4));
                    if(val==val_)
                        ok=true;
                        break;
                    end
                    
                end
                if(~ok)
                    error('Could not write register');
                end
                
            end
            
        end
        
        function val=readAddr(obj,addr_)
            addr=addr_;
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
            if(~exist('forceUpdate','var'))
                forceUpdate=false;
            end
            %             regVal_=cast(uint32(regVal),m.type);
            regVal_=cast(regVal,m.type);
            if(forceUpdate)
                obj.m_fw.setRegs(m.regName,regVal_,'forceupdate');
            else
                obj.m_fw.setRegs(m.regName,regVal_);
            end
            meta = obj.m_fw.genMWDcmd(m.regName);
            obj.privCmd(meta);

        end
        
        function k=getIntrinsics(obj)
            k=reshape([typecast(obj.read('CBUFspare'),'single');1],3,3)';
            obj.privRecFunc('getIntrinsics',{},{k});
        end
        
        
        function write(obj,regName,regVal)
            
            m=obj.m_fw.getMeta(regName);
            if(length(m)~=1)
                error('bad register name');
            end
            obj.writeAddr(uint32(m.address),regVal);
            
            
            
        end
        
        
        
        function fw=getFirmware(obj)
            fw=obj.m_fw;
            obj.privRecFunc('getFirmware',{},{fw});
        end
        
        
        
        function frame = getFrame(obj,n)
            if(~exist('n','var'))
                n=1;
            end
            stream(1) = obj.privGetSingleFrame();%capture atleast 1
            for i = 2:n
                stream(i) = obj.privGetSingleFrame();%#ok
            end
            if(length(stream)>1)
                meanNoZero = @(m) sum(double(m),3)./sum(m~=0,3);
                collapseM = @(x) meanNoZero(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]));
                frame.z=uint16(collapseM('z'));
                frame.i=uint8(collapseM('i'));
                frame.c=uint8(collapseM('c'));
            else
                frame=stream;
            end
            
            
            if(n~=-1)%do not save it to rec stream (for display usages)
                obj.privRecFunc('getFrame',{n},{frame});
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
            res = obj.privCmd('mwd a00d01f4 a00d01f8 00000fff'); % shadow update
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
        
        function tmptr=getTemperature(obj)
            [~,val]=obj.cmd('irb e2 13 02');
            tmptr=(double(val(1)))* 0.8046 +double((val(2)))* 0.00314296875-53.2358;
            obj.privRecFunc('getTemperature',{},{tmptr});
        end
        
        
        function v=getVersion(obj)
            [~,v]=obj.cmd('ERB 210 8');
            v=vec(dec2hex(fliplr(v))')';
            v=v(1:8);
        end
        function displayStream(obj)
            f=figure('numbertitle','off','menubar','none');
            t = timer;
            t.TimerFcn = @(varargin) obj.privDispFigRefresh(f);
            t.Period = 1;
            t.ExecutionMode = 'fixedRate';
            f.CloseRequestFcn =@(varargin) HWinterface.sprivDispFigClose(t);
            start(t);
        end
        function hwa = assertions(obj)
            % Read hwa status and second level per block
            blocks = {'top','io','pmg','afe','apdctl','proj','ansync','digg','rast','dcor','dest','cbuf','jfil','algo','fg','lcp','secc','soc','pmg_depth','vdf','usb','mipit_tx','tproc','dma','stat','imu','jpeg','fsu','NA','NA','cam_pmg','webcam_isp'};
            [~,status] = obj.cmd('mrd A0070308 A007030c');% // HWA status
            status = fliplr(logical(dec2bin(status)-'0'));
            status = [status,false(1,numel(blocks)-numel(status))];
            fprintf('\n');
            % Top address is A007030c A0070310
            topAddr = hex2dec('A007030c');
            shift = 4*(0:32)';
            shift(11) = [];% CBUF skips 1 address according to document, but it looks like a mistake. dest skips 1.
            shift(14:end) = shift(14:end) - 4; % Algo is the same as jfil? makes no sense.
            hwa = struct;
            for i = 1:numel(blocks)
                if status(i)
                    [~,blockStatus] = obj.cmd(sprintf('mrd %x %x',topAddr+shift(i),topAddr++shift(i)+4));
                    %                     fprintf(' -%s status: %08x.\n',blocks{i},blockStatus);
                    hwa.(blocks{i}) = sprintf('%08x',blockStatus);
                end
            end
            
        end
    end
end



