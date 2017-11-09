function randomize(obj,outputFile,regsList)
%TODO: handle constraints
regStruct=obj.m_registers;
if(~exist('regsList','var'))
    regsList = strcat({regStruct.algoBlock},{regStruct.algoName});
    regsList([regStruct.autogen]~=0)=[];
end

i1 = strcmp(regsList,'FRMWtxCode');
i2 = strcmp(regsList,'GNRLcodeLength');
if find(i1) < find(i2)
    regsList{i1} = 'GNRLcodeLength';
    regsList{i2} = 'FRMWtxCode';
end

allRegs = strcat({regStruct.algoBlock},{regStruct.algoName});
nanifempty = @(x) iff(isempty(x),nan,x);
indList = vec(cellfun(@(x) nanifempty(find(strcmp(allRegs,x))),regsList,'uni',false))';%#ok
bd = cellfun(@(x) any(isnan(x)),indList);
if(any(bd))
    error('Could not find register: %s',cell2str(regsList(bd)));
end

for k=1:length(indList)
    %%
    i=indList{k}(1);
    if(regStruct(i).autogen~=0)
        error('Cannot randomize autogen register (%s)',[regStruct(i).algoBlock regStruct(i).algoName]);
    end
    nvals = length(indList{k})*regStruct(i).arraySize;
    vals=[];
    if(isstruct(regStruct(i).rangeStruct))
        for j=1:length(regStruct(i).rangeStruct.scalar)
            p=round(regStruct(i).rangeStruct.scalar(j).p);
            val = ones(1,p)*regStruct(i).rangeStruct.scalar(j).val;
            
            vals = [vals val];%#ok
        end
    end
    
    for j=1:length(regStruct(i).rangeStruct.fromTo)
        x0 = regStruct(i).rangeStruct.fromTo(j).val0;
        x1 = regStruct(i).rangeStruct.fromTo(j).val1;
        p = round(regStruct(i).rangeStruct.fromTo(j).p);
        val = rand(1,p)*(x1-x0)+x0;
        
        vals = [vals val];%#ok
    end
    
    switch(regStruct(i).type)
        case {'uint4','uint2'}
            outType='uint8';
        case {'int10'}
            outType='int16';
        case {'uint12'}
            outType='uint16';
        otherwise
            outType=regStruct(i).type;
    end
    vals =vals(randi(length(vals),1,nvals));
    %special cases
    switch([regStruct(i).algoBlock regStruct(i).algoName])
        case 'GNRLcodeLength'
            while 1              
                try
                    vals =round(vals/2)*2;
                    code = Codes.propCode(vals,1).';  
                    break
                catch e
                    vals = [vals val];
                    vals =vals(randi(length(vals),1,nvals));
                    vals =round(vals/2)*2;
                end
            end
        case 'FRMWtxCode'
            codeLen = length(code);
            vals = uint32([0 0 0 0]);
            for ic = 1:(floor(codeLen/32) + 1)
                range = [1 + (ic-1)*32, min(codeLen - (ic-1)*32,32) + (ic-1)*32];
                vals(ic) = uint32(bin2dec(num2str(code(range(1):range(2)),'%d')));
            end
        case 'JFILsort1iWeights'
            vals = floor(vals/sum(vals)*128);
        case 'JFILsort2iWeights'
            vals = floor(vals/sum(vals)*128);
        case 'JFILsort3iWeights'
            vals = floor(vals/sum(vals)*128);
        case 'JFILsort1dWeights'
            vals = floor(vals/sum(vals)*128);
        case 'JFILsort2dWeights'
            vals = floor(vals/sum(vals)*128);
        case 'JFILsort3dWeights'
            vals = floor(vals/sum(vals)*128);
        
            
    end
    regs.(regStruct(i).algoBlock).(regStruct(i).algoName) = cast(vals,outType);
    
end
obj.setRegs(regs,outputFile);

end