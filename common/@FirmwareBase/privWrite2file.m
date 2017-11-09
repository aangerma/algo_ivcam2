function privWrite2file( obj,outputFn,outputType)

headers = { 'regName' 'base' 'value' };


switch(outputType)
    case 'asic'
        skip = cellfun(@(x) any(strcmp(x,{'EPTG'})),{obj.m_registers.algoBlock});
    case {'config','calib'}
        skip =~strcmp(outputFn,{obj.m_registers.updated});
    case 'all'
        skip = false(length(obj.m_registers),1);
    case 'static'
        skip = [obj.m_registers.autogen];
    otherwise
        error('unknown write type');
end

okregs = obj.m_registers(~skip);
[~,o]=sort({okregs.uniqueID});
okregs=okregs(o);
if(strcmp(outputType,'asic'))
    %%% add Regs suffix
    okregs = arrayfun(@(s) setfield(s,'regName',['Regs' s.regName]),okregs);%#pl
    dvals = find([okregs.base]=='d');
    for i=dvals
        okregs(i).value = dec2hex(uint32(str2double(okregs(i).value)));
        okregs(i).base = 'h';
    end
    bvals = find([okregs.base]=='b');
    for i=bvals
        okregs(i).value = dec2hex(uint32(bin2dec(okregs(i).value)),ceil(okregs(i).arraySize/4));
        okregs(i).base = 'h';
    end
    fvals = find([okregs.base]=='f');
    for i=fvals
        okregs(i).value = dec2hex(typecast(single(str2double(okregs(i).value)),'uint32'));
        okregs(i).base = 'h';
    end
    
end

order = {'MTLB','EPTG','FRMW','GNRL','DIGG','RAST','DCOR','DEST','CBUF','JFIL','PCKR','STAT'};
infifempty =@(x) iff(isempty(x),inf,x);
[~,o]=sort(cellfun(@(x) infifempty(find(strcmpi(x,order),1)),{okregs.algoBlock}));

okregs = okregs(o);
filed2mat =@(f) char(vec({okregs.(f)})); 
n = length(okregs);
txt=[filed2mat('regName') repmat(' ',n,1) filed2mat('base') filed2mat('value') repmat(char([13 10]),n,1)];

fid = fopen(outputFn,'w');
if(fid==-1)
    warning('privWrite2file: Could not write to file (%s)',outputFn);
else
    fprintf(fid,'%s',txt');
    fclose(fid);
end

end



