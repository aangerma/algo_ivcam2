% Concrete singleton implementation
classdef FirmwareBase <handle
    
    properties (Access=private)
        m_registers
        m_luts
        m_tablesFolder
        m_regHandle
        m_bootCalcsFunction
    end
    
    properties (Constant)
        typeList =     {'logical','double','single','uint8','int8' ,'uint16', 'int16','uint32', 'int32','uint64','int64'};
        typeUintList = {'uint8'  ,'uint64','uint32','uint8','uint8','uint16','uint16','uint32','uint32','uint64','uint64'};
    end
    
    
    methods (Access=public)
        
        function obj = FirmwareBase(tablesFolder, bootCalcsFunction)
            
            if (~exist('tablesFolder','var') || isempty(tablesFolder))
                error('Firmware tables folder is not provided');
            end
            
            obj.m_tablesFolder = tablesFolder;
            
            if (~exist('bootCalcsFunction','var'))
                bootCalcsFunction = [];
            elseif (~isa(bootCalcsFunction, 'function_handle'))
                error('bootCalcsFunction should be a function handle');
            end
            
            obj.m_bootCalcsFunction = bootCalcsFunction;
            
            obj.m_regHandle = 'error';
            
            obj.privLoadRegisters();
            obj.privLoadLUTs();
            % obj.privBootCalcs();
            % obj.privConstraints();
            
        end
        
        function [regsData,indx]=getMeta(obj,regNameKey)
            indx=regexpi({obj.m_registers.regName},regNameKey);
            indx=cellfun(@(x) ~isempty(x),indx);
            regsData = obj.m_registers(indx);
        end
        
        function rewriteRegisterFiles(obj)
            rMetaDataFilename = [obj.m_tablesFolder filesep 'regsDefinitions.frm'];
            obj.privRewriteRegisterDefFile(rMetaDataFilename);
        end
        
        function varargout=disp(obj,regNameKey)
            if(~exist('regNameKey','var'))
                regNameKey='.';
            end
            r=regexpi({obj.m_registers.regName},regNameKey);
            r=cellfun(@(x) ~isempty(x),r);
            regList = obj.m_registers(r);
            if(isempty(regList))
                txt='';
            else
                [~,o]=sort({regList.uniqueID});
                regList = regList(o);
                %%
                txt = [ {regList.regName}' arrayfun(@(x) ' ',1:length(regList),'uni',0)' {regList.base}' {regList.value}' ];
                
                txt(:,end)=strcat(txt(:,end),newline);
                txt=arrayfun(@(i) char(strcat(txt(:,i),char(9))) ,1:size(txt,2),'uni',false);
                txt=[txt{:}];
            end
            if(nargout==0)
                disp(txt);
            else
                txt=[txt ones(size(txt,1),1)*newline];
                varargout{1}=txt;
            end
        end
        
        
        function setRegs(varargin)
            obj = varargin{1};
            if(nargin==2 && isa(varargin{2},'char')) %csvFileName
                vals = FirmwareBase.sprivReadConfigurationFile(varargin{2});
                updatedBy = varargin{2};
            elseif(nargin==3 && isa(varargin{2},'struct')) %regs_struct + file
                s = varargin{2};
                vals = obj.privAlgoStruct2AsicStruct( s );
                updatedBy = varargin{3};
            elseif(nargin==3 && isa(varargin{2},'char')) %single reg
                
                [blockName,algoReg] = FirmwareBase.sprivConvertRegName2blockNameId(varargin{2});
                s.(blockName).(algoReg)=varargin{3};
                vals = obj.privAlgoStruct2AsicStruct( s );
                updatedBy = [];
            else
                error('incorrect input for FirmwareBase.setRegs');
            end
            
            privUpdate( obj,vals,updatedBy );
            %reset autogen
            if(~strcmpi(updatedBy,'autogen'))
                updatetag = [obj.m_registers.autogen]==1;
                if(nnz(updatetag)~=0)
                    for i=find(updatetag)
                        obj.m_registers(i).autogen=-1;
                    end
                end
            end
        end
        
        function setRegHandle(obj,t)
            obj.m_regHandle=t;
        end
        
        function runBootCalcs(obj)
            obj.privConstraints(); %check non autogen data
            obj.privBootCalcs();
            obj.privConstraints();
        end
        
        function obj=setLut(obj,lutsStruct)
            if(ischar(lutsStruct) && exist(lutsStruct,'file'))
                [~,fn]=fileparts(lutsStruct);
                [block,algoName]=FirmwareBase.sprivConvertRegName2blockNameId(fn);
                val=typecast(single((io.readBin(lutsStruct))),'uint32');
                luts.(block).(algoName)=vec(uint32(val))';
                obj.setLut(luts);
                return;
            end
            blockNames = fieldnames(lutsStruct);
            
            for i=1:length(blockNames)
                regNames = fieldnames(lutsStruct.(blockNames{i}));
                for j = 1:length(regNames)
                    lutName = [blockNames{i} regNames{j}];
                    lut = lutsStruct.(blockNames{i}).(regNames{j});
                    
                    indx =find(strcmpi({obj.m_luts.lutName},lutName));
                    if(isempty(indx))
                        error('Unknonw LUT name %s',lutName);
                    end
                    if(max(lut)>2^obj.m_luts(indx).elemSize-1)
                        error('Max value (%d) too big (expected %d',max(lut),2^obj.m_luts(indx).elemSize-1);
                    end
                    
                    if(length(obj.m_luts(indx).data) ~=length(lut))
                        error('Bad LUT %s length (expected: %d,actual: %d)',lutName,length(obj.m_luts(indx).data),length(lut));
                    end
                    obj.m_luts(indx).data = lut;
                end
            end
        end
        
        function [regs,luts] = get(obj)
            runBootCalcs(obj)
            [regs,luts]=obj.privGetNocalcs();
        end
        
        
        % Make a copy of a handle object.
        function new = copy(this)
            % Instantiate new object of the same class.
            new = feval(class(this));
            new.m_tablesFolder = this. m_tablesFolder;
            new.m_registers = this.m_registers;
            new.m_luts = this.m_luts;
            
        end
        
        function diff(this,other)
            this_regs = this.getRegs;
            other_regs = other.getRegs;
            fields = fieldnames(this_regs);
            for i=1: length(fields)
                regs = fieldnames(this_regs.(fields{i}));
                for j = 1:length(regs)
                    if(this_regs.(fields{i}).(regs{j}) ~= other_regs.(fields{i}).(regs{j})  )
                        disp(['DIFF- REGS: ' fields{i} regs{j} ' in this is: ' num2str(this_regs.(fields{i}).(regs{j})) ...
                            ' and in the input is: '  num2str(other_regs.(fields{i}).(regs{j})) ]);
                    end
                end
            end
            
            this_luts = this.getLuts;
            other_luts = other.getLuts;
            fields = fieldnames(this_luts);
            
            for i=1: length(fields)
                luts = fieldnames(this_luts.(fields{i}));
                for j = 1:length(luts)
                    if(sum(this_luts.(fields{i}).(luts{j}) ~= other_luts.(fields{i}).(luts{j})) ~= 0  )
                        disp(['DIFF- LUTS: ' fields{i} luts{j} ' this & input are different' ]);
                    end
                end
            end
        end
        
        function writeConfig4asic(obj, outputFn)
            privWrite2file( obj,outputFn,'asic');
        end
        
        function writeUpdated(obj, outputFn)
            privWrite2file( obj,outputFn,'config');
        end
        
        function writeMWDfile(obj,outfn,regTokens)
            if(~exist('regTokens','var') || isempty(regTokens))
                regTokens={'.'};
            elseif(~iscell(regTokens))
                regTokens={regTokens};
            end
            ind=[];
            for t=regTokens(:)'
                r=regexpi({obj.m_registers.regName},t);
                ind=[ind find(cellfun(@(x) ~isempty(x),r))];%#ok
            end
            m = num2cell([[obj.m_registers(ind).address]' [obj.m_registers(ind).address]'+4 Firmware.sprivRegstruct2uint32val(obj.m_registers(ind))]);
            m=[m {obj.m_registers(ind).regName}']';
            fid=fopen(outfn,'w');
            fprintf(fid,'mwd %08x %08x %08x //%s\n',m{:});
            fclose(fid);
            
        end
        
        
        
        
        writeDefs4asic(obj, outputFn) %seperate implementation
        randomize(obj,outputFile,regsList)
        
    end % public methods
    
    
    
    
    methods (Static=true, Access=public)
        
        b = dec2binFAST(d,n)
        regs = mergeRegs(regs,autogenRegs)
        
    end
    
    
    methods (Static=true, Access=private)
        [metaData,errMsg]         = sprivReadAsicFile              (filename,rewriteTidy)
        [values,blkIds,errMsg]    = sprivReadConfigurationFile     (filename,rewriteTidy)
        [relations,errMsg]        = sprivReadRelationsFile         (filename)
        regs                      = sprivRmData2struct             (valStruct,blockIDs)
        [valid,allValues]         = sprivIsValidValue              (stringIn,valueIn)
        v                         = sprivReadCSV                   (fn,rewriteTidy)
        regName                   = sprivConvertBlockNameId2regName(s)
        [blockName,algoReg,subId] = sprivConvertRegName2blockNameId(regName)
        val                       = sprivRegstruct2val             (s)
       val                       = sprivRegstruct2uint32val             (s)

        score                     = sprivStringDist                (string1,string2)
        s                         = sprivSizeof                    (typestr)
        [b,v]                     = sprivGetBaseVal                (txt)
    end
    
    
    methods (Access=private)
        privLoadLUTs( obj )
        privLoadRegisters(obj)
        
        privSave2ConfigFile(obj,structVals)
        privWrite2file( obj,outputFn,asicOuput)
        privUpdate( obj,vals,token )
        privBootCalcs(obj,updateBlocks)
        privRewriteRegisterDefFile     (obj,fn)
        privConstraints(obj)
        vals                      = privAlgoStruct2AsicStruct     (obj,s)
        
        function [regs,luts]=privGetNocalcs(obj)
            regs = FirmwareBase.sprivRmData2struct(obj.m_registers);
            
            for i=1:length(obj.m_luts)
                luts.(obj.m_luts(i).algoBlock).(obj.m_luts(i).algoName)=obj.m_luts(i).data;
            end
        end
    end
    
end

