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
        m_streamWithcolor        logical
        usefullRegs
        m_colorResolution
        m_rgbFR
    end
    
    
    
    methods ( Access=private)
        function frame=privGetSingleFrame_FG(obj)
            %get single frame
            imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth, 30000);
            % get depth
            imageObj = imageCollection.Images.Item(0);
            dImByte = imageObj.Item(0).Data;
            frame.fg = cast(dImByte,'uint8');
        end
        
        
        
        function frames=privGetSeveralFrames(obj,n)
            %get single frame
            imageCollection = obj.m_dotnetcam.Stream.GetFrames(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth,n, 30000);
            % get depth
            frames = struct('z',[],'i',[],'c',[]);
            for i=1:imageCollection.Count
                currImage = imageCollection.Item(i-1);
                imageObj = currImage.Images;
                dImByte = imageObj.Item(0).Item(0).Data;
                frames(i).z = typecast(cast(dImByte,'uint8'),'uint16');
                frames(i).z = reshape(frames(i).z(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);
                % get IR
                iImByte = imageObj.Item(1).Item(0).Data;
                frames(i).i = cast(iImByte,'uint8');
                frames(i).i = reshape(frames(i).i(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);
                
                % get C
                cImByte = imageObj.Item(2).Item(0).Data;
                cIm8 = cast(cImByte,'uint8');
                frames(i).c = bitand(cIm8(:),uint8(15))';
                frames(i).c = reshape(frames(i).c(1:end-obj.usefullRegs.PCKR.padding),obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize);
            end
            %             if obj.usefullRegs.PCKR.padding>0
            %                nRows2Add =  obj.usefullRegs.PCKR.padding/obj.usefullRegs.GNRL.imgHsize;
            %                frame.z = [frame.z;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
            %                frame.c = [frame.c;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
            %                frame.i = [frame.i;zeros(nRows2Add,obj.usefullRegs.GNRL.imgHsize)];
            %             end
        end
        
        function frame=privGetSingleFrame(obj)
            %get single frame
            imageCollection = obj.m_dotnetcam.Stream.GetFrame(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth, 15000);
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
        
        function [I] = privReadColorStream(obj,data)           
              data = reshape(data,obj.m_colorResolution);
              Y = double(bitand(data,255));
              
              I = uint8(Y');
              %{
              %for RGB and not just grayscale:
              
              U = zeros(imSize,'double');
              V = zeros(imSize,'double');
              UV = bitshift(data,-8);
              U(:,1:2:end) = UV(:,1:2:end);
              U(:,2:2:end) = UV(:,1:2:end);
              V(:,1:2:end) = UV(:,2:2:end);
              V(:,2:2:end) = UV(:,2:2:end);

              C = Y - 16;
              D = U - 128;
              E = V - 128;
              
              R = uint8((298*C+409*E+128)/256);
              G = uint8((298*C-100*D-208*E+128)/256);
              B = uint8((298*C+516*D+128)/256);

              Irgb(:,:,1)=B;
              Irgb(:,:,2)=G;
              Irgb(:,:,3)=R;
              Irgb = uint8(Irgb);
            %}
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
            %if(~logical(obj.read('JFILupscalexyBypass')))
            %    if(logical(obj.read('JFILupscalex1y0')))
            %        obj.usefullRegs.GNRL.imgHsize=2*obj.usefullRegs.GNRL.imgHsize;
            %    else
            %        obj.usefullRegs.GNRL.imgVsize=2*obj.usefullRegs.GNRL.imgVsize;
            %    end
            %end
            obj.usefullRegs.GNRL.zNorm = obj.z2mm;
        end
        function [res,val] = cmd(obj,str)
            [res,val]=obj.privCmd(str);
            
            obj.privRecFunc('cmd',{str},{res,val});
        end
        
        %startStream(obj);
        startStream(obj,FrameGraberMode,resolution,colorResolution,rgbFR);
        function stopStream(obj)
            if(obj.m_dotnetcam.Stream.IsDepthPlaying)
                %                 obj.runScript(obj.getPresetScript('stopStream'));
                obj.m_dotnetcam.Close();
                obj.m_streamWithcolor = false;
            end
            
            
        end
        function saveRecData(obj)
            if(~isempty(obj.m_recfn))
                recData = obj.m_recData;%#ok
                save(obj.m_recfn,'recData');
            end
        end
        %destructor
        function delete(obj)
            obj.stopStream();
            obj.saveRecData();
        end
        
        setupRF(obj,codeLen,decRatio);
        [ rfZ,rfI,rfC ] = rfGet( obj, N);
        burn2device(obj,basedir,burnCalib,burnConfig);
        cma = readCMA(obj,nAvg);
        setConfidenceAs(obj, input );
        burnCalibConfigFiles( obj, directory,verbose,fileType );
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
            obj.m_streamWithcolor = false;
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
            [vals,algoNames, addr]=obj.read(regTokens);
            s=[num2cell(vals) addr algoNames]';
            fprintf('%08x // addr: %s | %s \n',s{:});
            
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
        function [vals,algoNames,addr]=read(obj,regTokens)
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
            addr = cellfun(@dec2hex, {meta{:,1}}', 'UniformOutput', false);
            
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
            k([2,3,4,6]) = 0;
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
        function fwVersion = getFWVersion(obj)
            % Checks if fw version is smaller (or equal) to 1.1.3.77
            gvdstr = obj.cmd('gvd');
            linenum = strfind(gvdstr,'FunctionalPayloadVersion:');
            gvdTargetLine = gvdstr(linenum:end);
            fwVersionLine = strsplit(gvdTargetLine);
            fwVersion = fwVersionLine{2};
            
        end
        
        function frames = getColorFrameRAW(obj,n)

            if ~obj.m_streamWithcolor
                obj.startStream(false,[],obj.m_colorResolution,obj.m_rgbFR);
            end
            if(~exist('n','var'))
                n=1;
            end
            
            imageCollection = obj.m_dotnetcam.Stream.GetFrames(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Color,n, 30000);
            % extract images
            frames = struct('color',[]);
            for i=1:imageCollection.Count
                currImage = imageCollection.Item(i-1);
                imageObj = currImage.Images;
                dImByte = imageObj.Item(0).Item(0).Data;
                frame = typecast(cast(dImByte,'uint8'),'uint16');
                frames(i).color = frame;    %obj.privReadColorStream(frame, colorRes);
            end
        end
        
        
        function frames = getColorFrame(obj,n)
            
            if ~obj.m_streamWithcolor
                colorRes=[1920 1080];
                rgbFR=30;
                obj.startStream(false,[],colorRes,rgbFR);
            end
            if(~exist('n','var'))
                n=1;
            end
            
            imageCollection = obj.m_dotnetcam.Stream.GetFrames(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Color,n, 30000);
            % extract images
            frames = struct('color',[]);
            for i=1:imageCollection.Count
                currImage = imageCollection.Item(i-1);
                imageObj = currImage.Images;
                dImByte = imageObj.Item(0).Item(0).Data;
                frame = typecast(cast(dImByte,'uint8'),'uint16');
                frames(i).color = obj.privReadColorStream(frame);
            end
        end
        
        
        function frame = getFrame(obj,n,postproc,rot180,resolution)
            if ~exist('resolution','var') || isempty(resolution)
                obj.startStream;
            else
                obj.startStream(0,resolution);
            end
            if(~exist('n','var'))
                n=1;
            end
            if(~exist('rot180','var'))
                rot180=0;
            end
            if (~exist('postproc','var'))
                postproc = true;
            end
            if n < 2
                stream(1) = obj.privGetSingleFrame();%capture atleast 1
                for i = 2:n
                    stream(i) = obj.privGetSingleFrame();%#ok
                end
            else
                stream = obj.privGetSeveralFrames(n);%capture atleast 1
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
            if rot180
                for i = 1:numel(frame)
                    frame(i).i = rot90(frame(i).i,2);
                    frame(i).z = rot90(frame(i).z,2);
                    frame(i).c = rot90(frame(i).c,2);
                end
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
        function [shifts] = pzrShifts(obj)
            str = obj.cmd('mrd fffe18a8 fffe18ac');
            shifts(1) = hex2dec(str(end-7:end));
            str = obj.cmd('mrd fffe18ac fffe18b0');
            shifts(2) = hex2dec(str(end-7:end));
            str = obj.cmd('mrd fffe18b0 fffe18b4');
            shifts(3) = hex2dec(str(end-7:end));
        end
        function [ibias,vbias] = pzrPowerGet(obj,i,N)
            ibias = zeros(1,N);
            vbias = zeros(1,N);
            for k = 1:N
                str = obj.cmd(sprintf('PZR_POWER_GET %1.0f',i));
                lines = strsplit(str,newline);
                line = strsplit(lines{1},{':',' '});
                vbias(k) = str2num(line{2});
                line = strsplit(lines{2},{':',' '});
                ibias(k) = str2num(line{2});
                pause(0.005);
            end
            ibias = mean(ibias);
            vbias = mean(vbias);
        end
        function [lddTmptr,mcTmptr,maTmptr,apdTmptr ]=getLddTemperature(obj,N)
            if ~exist('N','var')
                N = 10;
            end
            getTmptr = zeros(N,3);
            
            tSense = zeros(N,1);
            vSense = zeros(N,1);
            for i = 1:N
                strtmp = obj.cmd('TEMPERATURES_GET');
                lines = strsplit(strtmp,newline);
                for k = 1:numel(lines)
                    line = strsplit(lines{k},{':',' '});
                    if numel(line) > 1
                        getTmptr(i,k) = str2num(line{2});
                    end
                end
                pause(0.005);
            end
            tSense = mean(tSense);
            vSense = mean(vSense);
            lddTmptr = mean(getTmptr(:,1));
            mcTmptr = mean(getTmptr(:,2));
            maTmptr = mean(getTmptr(:,3));
            apdTmptr = mean(getTmptr(:,4));
            
        end
        function factor = z2mm(obj)
            % Divide z image by this value to get depth in mm
            factor = uint16(typecast(obj.read('GNRLzNorm'),'single'));
        end
        function [info,serial,isId] = getInfo(obj)
            info = obj.cmd('gvd');
            expression = 'OpticalHeadModuleSN:.*';
            ma = regexp(info,expression,'match');
            split = strsplit(ma{1});
            serial = split{2};
            serial = serial(end-7:end);
            
            expression = 'StrapState:.*';
            ma = regexp(info,expression,'match');
            split = strsplit(ma{1});
            StrapState = split{2};
            unitType = mod(hex2dec(StrapState(end-3)),4);
            assert(any(unitType == [0,3]),sprintf('StrapState bits 13-12 should be either 10 or 11. Can not identify unit type. %s',StrapState));
            isId = unitType == 3;
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
        
        function shutDownLaser(obj)
            obj.cmd('iwb e2 06 01 00'); % Remove bias
            obj.cmd('iwb e2 08 01 0'); % modulation amp is 0
            obj.cmd('iwb e2 03 01 10');% internal modulation (from register)
        end
        
        function openLaser(obj)
            obj.cmd('iwb e2 03 01 9a');% internal modulation (from register)
            obj.cmd('iwb e2 08 01 0'); % modulation amp is 0
            obj.cmd('iwb e2 06 01 70'); % Add bias
        end
        
        
        function [result] = getPresetControlState(obj)
            try
                result = obj.m_dotnetcam.PropertyProvider.QueryProperty(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth, 'Gain');
            catch e
                error(e.message);
            end
        end
        
        function [] = setPresetControlState(obj,value)
            try
                obj.m_dotnetcam.PropertyProvider.SetProperty(IVCam.Tools.CamerasSdk.Common.Devices.CompositeDeviceType.Depth, 'Gain', value);
            catch e
                error(e.message);
            end
        end
        
        function [regs,bin] = readAlgoEEPROMtable(obj,EPROMstructure)
            % EPROMstructure: deafult or from mat file of specific calibration
            % read eprom from hardware
            [~,bin]=obj.cmd('erb 1200 200 ');
            
            % remove header (16 bytes)
            d=bin(17:end);
            if exist('EPROMstructure','var')
                regs=obj.m_fw.readAlgoEpromData(d,EPROMstructure);
            else
                regs=obj.m_fw.readAlgoEpromData(d);
            end
        end
    end
end



