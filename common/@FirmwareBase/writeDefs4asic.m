function writeDefs4asic(obj,outputFn)

obj.privBootCalcs();
obj.privConstraints();
skip = cellfun(@(x) any(strcmp(x,{'MTLB','POCU'})),{obj.m_registers.algoBlock});
regs = obj.m_registers(~skip);

headers = {'Name','Field Name','Base Address','Address','End Bit','Start Bit','Functionality','Default value','Unit','RW/RO','Top Unit','Shadow','Lock Unit','Reset signal','HW Set','Split Reg','CMD','Indicate upon write','Indicate upon read','Clear upon read','Write 1 to clear','Constraint','comments','Dont check in test registers','Absolute Address'};

shadowFlag = @(ri) iff(strcmp(ri.uniqueID(1:3),'100')==1,'','x');
%% write registers
dataRegs={};
for i=1:length(regs)
    v=cell(0,length(headers));
    arrsize = regs(i).arraySize;
    s=FirmwareBase.sprivSizeof(regs(i).type);
    
    defVal = regs(i).defaultValue;
    switch(defVal(1))
        case 'h'
            defVal=uint32(hex2dec(defVal(2:end)));
        case {'d','s'}
            defVal = uint32(str2double(defVal(2:end)));
        case 'f'
            defVal = typecast(single(str2double(defVal(2:end))),'uint32');
        case 'b'
            defVal = uint32(bin2dec(defVal(2:end)));
        otherwise
            error('unknonw type');
    end
    
    
    if(arrsize==1 || s==1)
        indx=1;
        
        v{indx,findColIndex(headers,'Name')}=sprintf('Regs%s',FirmwareBase.sprivConvertBlockNameId2regName(regs(i)));
        v{indx,findColIndex(headers,'Field Name')}=sprintf('Regs%s',FirmwareBase.sprivConvertBlockNameId2regName(regs(i)));
        v{indx,findColIndex(headers,'Start Bit')} = '0';
        v{indx,findColIndex(headers,'End Bit')} = num2str(arrsize*s-1);
        v{indx,findColIndex(headers,'Unit')} = regs(i).algoBlock;
        v{indx,findColIndex(headers,'Top Unit')} = regs(i).algoBlock;
%         if(s==1)
%             bitMask=uint32(bitshift(uint64(1),arrsize)-1);
%         else
%         bitMask=uint32(bitshift(uint64(1),FirmwareBase.sprivSizeof(regs(i).type))-1);
%         end
%         vh = bitand(defVal,bitMask);
%         vh = dec2hex(vh,ceil(arrsize*s/4));
%         v{indx,findColIndex(headers,'Default value')} = ['h'   vh ];
        v{indx,findColIndex(headers,'Default value')} = regs(i).defaultValue;
        
        v{indx,findColIndex(headers,'Constraint')} = regs(i).range;
        v{indx,findColIndex(headers,'Shadow')} = shadowFlag(regs(i));
        
    else
   
        
        
        
        
        
        
        
        
        for indx=1:arrsize
            DefValI=dec2hex(bitand(bitshift(defVal,-s*(indx-1)),2^s-1),ceil(s/4));
            v{indx,findColIndex(headers,'Name')}=sprintf('Regs%s',FirmwareBase.sprivConvertBlockNameId2regName(regs(i)));
            v{indx,findColIndex(headers,'Field Name')}=sprintf('Regs%s_S%01d',FirmwareBase.sprivConvertBlockNameId2regName(regs(i)),indx-1);
            v{indx,findColIndex(headers,'Start Bit')} = num2str(s*(indx-1));
            v{indx,findColIndex(headers,'End Bit')} = num2str(s*indx-1);
            v{indx,findColIndex(headers,'Unit')} = regs(i).algoBlock;
            v{indx,findColIndex(headers,'Split Reg')} = '1';
            v{indx,findColIndex(headers,'Top Unit')} = regs(i).algoBlock;
            v{indx,findColIndex(headers,'Default value')} = ['h' DefValI];
            v{indx,findColIndex(headers,'Constraint')} = regs(i).range;
            v{indx,findColIndex(headers,'Shadow')} =  shadowFlag(regs(i));
        end
    end
    
    dataRegs=[dataRegs;v];
    
end
%
%  [~,ordr]=sort({regs.uniqueID});
 [~,ordr] = sort(dataRegs(:,1));
dataRegs = dataRegs(ordr,:);



%% write to file
data = [headers;dataRegs];
data=cellfun(@(x) iff(isempty(x),'',x),data,'uni',0);
datatxt='';
for i=1:size(data,2)
    datatxt = [datatxt char(data(:,i))]; %#ok<*AGROW>
    datatxt(:,end+1)=',';
end
datatxt(:,end)=10;

fid = fopen(outputFn,'w');
if(fid==-1)
    warning('privWrite2file: Could not write to file (%s)',outputFn);
else
    fprintf(fid,'%s',datatxt');
    fclose(fid);
end
end



function ind = findColIndex(v,htxt)
ind = find(strcmpi(v,htxt), 1);
if(isempty(ind))
    error('Could not find ''%s'' in headers',htxt);
end
end

