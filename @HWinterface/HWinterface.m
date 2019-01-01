%{
iwb e2 01 06 // turn laser off
%}
% Concrete singleton implementation
classdef HWinterface <handle
    
    properties (Access=private)
        m_dotnetcam;
        m_fw                     Firmware
        m_presetScripts
        m_recData
        m_recfn                  char
        
        usefullRegs
        
    end
    
    
    
    methods ( Access=private)
       function frame=privGetSingleFrame_FG(obj)
            %get single frame
            imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth, 15000);
            % get depth
            imageObj = imageCollection.Images.Item(0);
            dImByte = imageObj.Item(0).Data;
            frame.fg = cast(dImByte,'uint8');
        end
       
        function frame=privGetSingleFrame(obj)
            %get single frame
            imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth);
            % get depth
            imageObj = imageCollection.Images.Item(0);
            dImByte = imageObj.Item(0).Data;
            frame.z = typecast(cast(dImByte,'uint8'),'uint16');
            frame.z = reshape(frame.z(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);
            % get IR
            imageObj = imageCollection.Images.Item(1);
            iImByte = imageObj.Item(0).Data;
            frame.i = cast(iImByte,'uint8');
            frame.i = reshape(frame.i(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);
            
            % get C
            imageObj = imageCollection.Images.Item(2);
            cImByte = imageObj.Item(0).Data;
            cIm8 = cast(cImByte,'uint8');
            frame.c = bitand(cIm8(:),uint8(15))';
            frame.c = reshape(frame.c(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);

%             if obj.usefullRegs.PCKR.padding>0
%                nRows2Add =  obj.usefullRegs.PCKR.padding/obj.usefullRegs.GNRL.imgHsize;
%                frame.z = [frame.z;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
%                frame.c = [frame.c;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
%                frame.i = [frame.i;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
%             end
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
        
        
        function privDispFigRefresh(obj,f)
            d=obj.getFrame();
            aa(1)=subplot(121,'parent',f);
            z=double(d.z)/obj.usefullRegs.GNRL.zNorm;
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
        function sz = streamSize(obj)
           sz = [obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize];
        end
        function setUsefullRegs(obj)
           obj.usefullRegs.PCKR.padding = obj.read('PCKRpadding');
           obj.usefullRegs.GNRL.imgVsize = obj.read('GNRLimgVsize');
           obj.usefullRegs.GNRL.imgHsize = obj.read('GNRLimgHsize');
           obj.usefullRegs.GNRL.zNorm = obj.z2mm;
        end
        function [res,val] = cmd(obj,str)
            [res,val]=obj.privCmd(str);
            
            obj.privRecFunc('cmd',{str},{res,val});
        end
        
        %startStream(obj);
        startStream(obj,FrameGraberMode,resolution);
        function stopStream(obj)
            if(obj.m_dotnetcam.Stream.IsDepthPlaying)
                obj.runScript(obj.getPresetScript('stopStream'));
                obj.m_dotnetcam.Close();
            end
            
            
        end
        
        %destructor
        function delete(obj)
            obj.stopStream();
            if(~isempty(obj.m_recfn))
                recData = obj.m_recData;%#ok
                save(obj.m_recfn,'recData');
            end
        end
        
        setupRF(obj,codeLen,decRatio);
        [ rfZ,rfI,rfC ] = rfGet( obj, N);
        burn2device(obj,basedir,burnCalib,burnConfig);
        cma = readCMA(obj,nAvg);
        setConfidenceAs(obj, input );
        %----------------------CONSTRUCTOR----------------------
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
                    obj.shadowUpdate();
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
        
        
        
        function frame = getFrame(obj,n,postproc)
            obj.startStream();
            if(~exist('n','var'))
                n=1;
            end
            if (~exist('postproc','var')) 
                postproc = true;
            end
            stream(1) = obj.privGetSingleFrame();%capture atleast 1
            for i = 2:n
                stream(i) = obj.privGetSingleFrame();%#ok
            end
            if(length(stream)>1) && postproc
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
        
     function frame = FG_getFrame(obj,n,res,pos)
            if(~exist('n','var'))
                n=1;
            end
            if(~exist('res','var'))
                res= [720 1280];
            end
            if(~exist('pos','var'))
                pos.left = 0;
                pos.top = 0;
            end
%% config FG grabber
            if(~obj.m_dotnetcam.Stream.IsDepthPlaying) % check that not in streaming
                obj.cmd('fgcfgbypass 1'); % bypass internal configuration by FW
                obj.cmd('mwd a0050004 a0050008 11'); % inverse direction bit for frame graber block
        
                if(res == [720 1280])         %res 720x1280
                    obj.runPresetScript('fg_time_1280x720');
                    limit_diff = hex2dec('3540');
                    top_range =  [256 17184];
                    left_range = [255 1023];
                else if (res == [600 800])    %res 800x600
                    obj.runPresetScript('fg_time_800x600');
                    limit_diff = hex2dec('1CC0');    
                    top_range =  [256 16348];
                    left_range = [255 1280];
                    else
                        % invalid resolution
                        error('invalid resolution');
                    end
                end
                pos.top = uint32(top_range(1)+ (pos.top/100)*(top_range(2)-top_range(1)));
                pos.left = uint32(left_range(1)+ (pos.left/100)*(left_range(2)-left_range(1)));
                LowLimit = dec2hex(pos.top);
                UpperLimit = dec2hex(pos.top + limit_diff);
                LeftOffset = dec2hex(pos.left);
                CmdLowLimit     = ['mwd a00a0034 a00a0038 ',LowLimit];
                CmdUpperLimit   = ['mwd a00a0030 a00a0034 ',UpperLimit];
                CmdLeftOffset   = ['mwd a00a0044 a00a0048 ',LeftOffset];
                obj.cmd(CmdLowLimit); 
                obj.cmd(CmdUpperLimit); 
                obj.cmd(CmdLeftOffset); 
                FG_mode = true;    
                obj.startStream(FG_mode,res);
            end
%%            
            stream(1) = obj.privGetSingleFrame_FG();%capture atleast 1
            for i = 2:n
                stream(i) = obj.privGetSingleFrame_FG();%#ok
            end
            frame=stream;
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
            if(~exist(fn,'file'))
                tt=tempname;
                fid=fopen(tt,'w');
                fprintf(fid,fn);
                fclose(fid);
                fn=tt;
            end
            
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
        function factor = z2mm(obj)
            % Divide z image by this value to get depth in mm
           factor = uint16(typecast(obj.read('GNRLzNorm'),'single'));
        end
        function [info,serial] = getInfo(obj)
            info = obj.cmd('gvd');
            expression = 'OpticalHeadModuleSN:.*';
            ma = regexp(info,expression,'match');
            split = strsplit(ma{1});
            serial = split{2};
        end
        function v=getSerial(obj)
            [~,v]=obj.cmd('ERB 210 8');
            v=vec(dec2hex(fliplr(v))')';
            if strcmp(v(1:8),'00000000')
                v = v(9:end);
            else
                v = v(1:8);
            end
        end
        function displayStream(obj)
            f=figure('numbertitle','off','menubar','none');
            t = timer;
            t.TimerFcn = @(varargin) obj.privDispFigRefresh(f);
            t.Period = 1/30;
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



