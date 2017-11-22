function privUpdate( obj,vals,updatedBy )
allRegNames = {obj.m_registers.regName};
for i=1:length(vals)
    
    reg_name = vals(i).regName;
    ind = strcmp(reg_name,allRegNames);
    if(~any(ind))
        bestmatch = minind(cellfun(@(x) obj.sprivStringDist(reg_name,x),allRegNames));
        errtxt = '';
        if(~isempty(updatedBy))
            errtxt = sprintf('Error while loading file %s\n',updatedBy);
        end
        switch(obj.m_regHandle)
            case 'ignore'
                warning('%sCould not find register %s (did you mean %s?)',errtxt,reg_name,allRegNames{bestmatch});
                continue;
            case 'nearest'
                warning('%sCould not find register %s, using %s instead',errtxt,reg_name,allRegNames{bestmatch});
                ind = bestmatch;
            otherwise
                error('%sCould not find register %s (did you mean %s?)',errtxt,reg_name,allRegNames{bestmatch});
        end
    end
    
    
    %reg name
    if(sum(ind)~=1)
        lindx = minind(cellfun(@(x) length(setdiff(unique(lower(x(5:end))),unique(lower(reg_name)))),{obj.m_registers.regName}));
        error('Bad register name:%s (closest match: %s)',reg_name,obj.m_registers(lindx).regName)
    end
    if(strcmpi(obj.m_registers(ind).type,'logical') && vals(i).base~='b' && vals(i).base~='h')
        error('Binary type registers should have default value in binary format to disable data abiguity (%s)',obj.m_registers(ind).regName);
    end
    
    if(any(obj.m_registers(ind).autogen~=0) && ~strcmp(updatedBy,'autogen'))
        warning('FIRMWARE:privUpdate:updateAutogen','Trying to set an autogenerated register(%s) - skipping',reg_name);
        continue;
    end
    if(strcmpi(updatedBy,'autogen') &&   obj.m_registers(ind).autogen==false)
        error('Cannot autogenerate register that is not marked as autogen in definition file(%s)',obj.m_registers(ind).regName);
    end
    if(vals(i).base~='f' && vals(i).base~='h' && strcmp(obj.m_registers(ind).type,'single') )
        error('floating point registers must get floating point data(%s)',obj.m_registers(ind).regName);
    end
    
    
    obj.m_registers(ind).base = vals(i).base;
    obj.m_registers(ind).value = vals(i).value;
    obj.m_registers(ind).comments = vals(i).comments;
    if(~isempty(updatedBy))
        obj.m_registers(ind).updated = updatedBy;
        if(strcmp(updatedBy,'autogen'))
            obj.m_registers(ind).autogen=1;
        end
    end
    
    
    
end
end