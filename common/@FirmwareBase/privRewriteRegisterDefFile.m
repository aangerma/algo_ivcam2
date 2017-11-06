function privRewriteRegisterDefFile(obj,filename)
%%
headers = {'uniqueID','regName','type'   ,'arraySize','defaultValue','autogen','range','functionallity'};
dataTxt = '';
delim = repmat(', ',length(obj.m_registers)+1,1);
for i=1:length(headers)
    switch(headers{i})
        case 'autogen'
        concatData = cellfun(@(x) iff(x~=0,'x',''), {obj.m_registers.autogen},'uni',0);
        case 'arraySize'
        concatData =arrayfun(@(x) num2str(x),[obj.m_registers.arraySize],'uni',0);
        case 'defaultValue'
            concatData = getBaseValSafe(obj.m_registers);
        otherwise
        concatData ={obj.m_registers.(headers{i})};
    end
    
    dataTxt=[dataTxt char([headers{i} concatData])  delim]; %#ok

end
dataTxt(:,end-1:end)=[];
dataTxt(:,end+1)=10;

fid = fopen(filename,'w');
fprintf(fid,dataTxt');
fclose(fid);

end

function c = getBaseValSafe(s)
c=cell(1,length(s));
for i=1:length(s)
    if(strcmp(s(i).type,'single') && s(i).base=='h')
        %handle float
        c{i} = sprintf('f%g',typecast(uint32(hex2dec(s(i).value)),'single'));
    elseif(~strcmp(s(i).type,'single') && s(i).base=='h')
        %non float hex
        n=FirmwareBase.sprivSizeof(s(i).type)*s(i).arraySize;
        v=sprintf('%08s',s(i).value);
        c{i} = ['h' v(end-ceil(n/4)+1:end)];
    else
        c{i} = [s(i).base s(i).value];
    end
end

end
