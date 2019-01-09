% Concrete singleton implementation
classdef HWinterfaceFile <handle
    
    properties (Access=private)
        m_fw
        m_recData;
        
        usefullRegs
    end
    
    methods (Access=private)
        
        function varo=privInOutRec(obj,funcName,varargin)
            if(~strcmp(funcName,obj.m_recData(1,1)))
                error('Recorded stream state is not aligned with func calls (expected: %s,called: %s)',obj.m_recData{1,1},funcName);
            end
            n=min(length(varargin{:}),length(obj.m_recData{1,2}));
            if(~isequal(obj.m_recData{1,2}(1:n),varargin{:}(1:n)))
                error('Recorded stream state is not aligned with func (input missmatch)');
            end
            varo=obj.m_recData{1,3};
            obj.m_recData=obj.m_recData(2:end,:);
        end
    end
    
    methods (Access=public)
        
        function varargout = cmd(obj,varargin)
            varargout=obj.privInOutRec('cmd',varargin);
        end
        
        %destructor
        function delete(obj)%#ok
            
        end
        
        
        
        function varargout=burn2device(obj,varargin)
        
        end
        
        function obj = HWinterfaceFile(recFile)
            obj.m_recData=load(recFile,'recData');
            obj.m_recData=obj.m_recData.recData;
           obj.m_fw = obj.m_recData{1,2}{:};
           obj.m_recData=obj.m_recData(2:end,:);
        end
        
        
        function varargout=getPresetScript(obj,varargin)
            varargout=obj.privInOutRec('getPresetScript',varargin);
        end
        
        function dispRegs(obj,varargin)%#ok
        end
        
        function varargout=writeAddr(obj,varargin)
        
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
        function startStream(obj,varargin)
            imgVsize = obj.read('GNRLimgVsize');
            obj.setUsefullRegs();
        end
        function setUsefullRegs(obj)
           obj.usefullRegs.PCKR.padding = obj.read('PCKRpadding');
           obj.usefullRegs.GNRL.imgVsize = obj.read('GNRLimgVsize');
           obj.usefullRegs.GNRL.imgHsize = obj.read('GNRLimgHsize');
           obj.usefullRegs.GNRL.zNorm = obj.z2mm;
        end
        function sz = streamSize(obj)
           sz = [obj.usefullRegs.GNRL.imgVsize,obj.usefullRegs.GNRL.imgHsize];
        end
        function setReg(obj,varargin)
            
        end
        
        function varargout=getIntrinsics(obj,varargin)
            varargout=obj.privInOutRec('getIntrinsics',varargin);
        end
        
        
        function write(obj,varargin)
            
            
        end
        
        function varargout=getFirmware(obj,varargin)
            varargout=obj.privInOutRec('getFirmware',varargin);
            
        end
        
        
        
        function varargout = getFrame(obj,varargin)
            %get frame for visualization
            if(nargin>1 && varargin{1}==-1)
                varargout={struct('z',zeros(480,640,'uint16'),'i',zeros(480,640,'uint8'),'c',zeros(480,640,'uint8'))};
            else
                varargout=obj.privInOutRec('getFrame',varargin);
            end
            
        end
        
        
        
        
        function shadowUpdate(obj)
%             varargout=obj.privInOutRec('shadowUpdate',varargin);
        end
        
        function varargout = runPresetScript(obj,varargin)
            
        end
        
        function varargout = runScript(obj,varargin)
%             varargout=obj.privInOutRec('runScript',varargin);
        end
        
          function tmptr=getTemperature(obj)
            [~,val]=obj.cmd('irb e2 13 02');
            tmptr=(double(val(1)))* 0.8046 +double((val(2)))* 0.00314296875-53.2358;
            
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
        function varargout=displayStream(obj,varargin)
            
            
        end
        function hwa = assertions(obj)%#ok
            
        end
        function factor = z2mm(obj)
            % Divide z image by this value to get depth in mm
           factor = uint16(typecast(obj.read('GNRLzNorm'),'single'));
        end
    end
end



