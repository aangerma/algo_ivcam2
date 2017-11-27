function outStruct = privAlgoStruct2AsicStruct(obj, inStruct )
%output should have reganme,base,value and comments
algoBlocks = fieldnames(inStruct);
outStruct=[];

%find unique regs and their type
allRegNames = {obj.m_registers.regName};
allRegNames = cellfun(@(x) iff(isempty(regexp(x,'_(?<num>[\d]+)', 'once')) ,x,x(1:regexp(x,'_(?<num>[\d]+)')-1)),allRegNames,'uni',false);
[allRegNames,uniqueInd] = unique(allRegNames);

allRegTypes = {obj.m_registers.type};
allRegTypes = allRegTypes(uniqueInd);

isAlgoBlock = cellfun(@(x) length(x)==4 && all(x==upper(x)),algoBlocks);
if(~all(isAlgoBlock))
    error('Input struct must hold algo block names (%s)',algoBlocks{find(~isAlgoBlock,1)});
end

for i = 1:length(algoBlocks)
    algoBlock = algoBlocks{i};
    algoNames = fieldnames(inStruct.(algoBlock));
    
    for j = 1:length(algoNames)
        algoName = algoNames{j};
        
        ind = strcmp([algoBlock algoName],allRegNames);
        if(~any(ind))
           bestmatch = minind(cellfun(@(x) obj.sprivStringDist([algoBlock algoName],x),allRegNames));
             error('Could not find register(%s, did you mean %s?)',[algoBlock algoName],allRegNames{bestmatch});
        end
        
        inval = inStruct.(algoBlocks{i}).(algoName);
        wantedClass = allRegTypes{ind};
        %check class range
        switch(wantedClass)
            case {'uint4','uint10','uint12'}
                assert(all(inval<=2^FirmwareBase.sprivSizeof(wantedClass)-1),'Input data and requested size missmatch')
            case {'int4','int10','int12'}
                assert(all(abs(inval)<=2^FirmwareBase.sprivSizeof(wantedClass)-2),'Input data and requested size missmatch')
        end
            
        
        
        if(~strcmp(class(inval),wantedClass) )
            if( isa(inval,'uint8') && strcmp('uint2',wantedClass))
                %OK
            elseif( isa(inval,'uint8') && strcmp('uint4',wantedClass))
                %OK
            elseif(isa(inval,'uint16') && strcmp('uint12',wantedClass))
                %OK
           elseif(isa(inval,'int16') && strcmp('int10',wantedClass))
                %OK
           elseif(~isa(inval,'logical') && strcmp('logical',wantedClass))
               inval = dec2bin(inval)=='1';
            else
                error('type of %s should be %s (got class %s)',[algoBlock algoName],wantedClass,class(inval));
            end
        end
        
        
        
        if(isa(inval,'double'))
            outval = single(inval);
        elseif(isa(inval,'logical'))
            outval = uint32(sum(bsxfun(@bitshift,uint32(reshape([inval(:);zeros(mod(32-length(inval),32),1)],32,[])),(0:31)')));
        elseif(isa(inval,'uint8') && strcmp(wantedClass,'uint4'))
               outval=sum(bsxfun(@bitshift,buffer_(inval,2),[0;4]),'native');
          elseif(isa(inval,'uint16') && strcmp(wantedClass,'uint12'))
               outval=sum(bsxfun(@bitshift,uint32(buffer_(inval,2)),[0;12]),'native');
          elseif(isa(inval,'int16') && strcmp(wantedClass,'int10'))
              maskedVal = bitand(typecast(inval,'uint16'),2^10-1);
               outval=sum(bsxfun(@bitshift,uint32(buffer_(maskedVal,2)),[0;10]),'native');
        else
            outval = inval;
        end
        
        
        outvalClass = class(outval);
        nzp=rem(rem(32-FirmwareBase.sprivSizeof(outvalClass)*length(outval),32)+32,32)/FirmwareBase.sprivSizeof(outvalClass);
        outval = [outval zeros(1,nzp)]; %#ok<AGROW>
        outval =     typecast(outval,'uint32');
        nregs = length(outval);
        
        rep = @(x) arrayfun(@(i) x,1:nregs,'uni',0);
        
        %%
        % s = struct('algoName',rep(algoName),'algoBlock',rep(algoBlock),'subReg',nan,'arraySize',{'32','32'},'range','[0:2^32-1]','value',arrayfun(@(i) dec2hex(i),outval,'uni',0),'comments',rep(''),'base',rep('h'),'type',rep(class(inval)),'regName',iff(nregs==1,[algoBlock algoName],arrayfun(@(i) sprintf('%s%s_%02d',algoBlock,algoName,i),0:nregs-1,'uni',false)));
        
        s = struct('value',arrayfun(@(i) dec2hex(i,8),vec(outval)','uni',0),...
            'comments',rep(''),...
            'base',rep('h'),...
            'regName',iff(nregs==1,[algoBlock algoName],arrayfun(@(i) sprintf('%s%s_%03d',algoBlock,algoName,i),0:nregs-1,'uni',false)));
        
        %inner checker
        switch(wantedClass )% class(inval)
            case {'single'}
                assert(all(vec(typecast(uint32(hex2dec({s.value})),'single'))==vec(inval)),'typeset failed in register %s = %f',s.regName,inval);
            case {'uint8','int8','uint16','int16','uint32','int32'}
                inval2 = typecast(uint32(hex2dec({s.value})),class(inval));
                assert(all(vec(inval2(1:length(inval)))==vec(inval)),'INTERNAL TYPE SET CHECK FAILED');
            case 'logical'
                inval2=fliplr(vec(cell2mat(cellfun(@(x) dec2binFAST(uint64(hex2dec(x)),32),fliplr({s.value}),'uni',0))=='1')');
                assert(all(inval2(1:length(inval))==inval),'INTERNAL TYPE SET CHECK FAILED')
            otherwise
        end
        
        
        
        
        outStruct = [outStruct s];%#ok
        
        
    end
end


end



