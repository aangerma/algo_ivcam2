function privConstraints( obj )
   constraintsFilename = [obj.m_tablesFolder filesep 'regsConstraints.frmw'];
   txt = fileread(constraintsFilename);
   lines = str2cell(txt,char(10));

%helperfunction
at = @(v,i) v(i+1); %#ok

for i=1:length(lines)
origLine=strtrim(lines{i});
    %if empty line or comment -> continue
    if(isempty(origLine) || origLine(1) == '%')
        continue;
    end
    
    %find regs names enclosed in [...]
    regStr = regexp(origLine,'\[\w+\]','match');    
    regStrInd = regexp(origLine,'\[\w+\]');
    
    line = origLine;
    
    %ex: ...[JFILedge1maxTh]... -> ...str2double(obj.m_registers(175).value)...
    for j=1:length(regStrInd)
        str = regStr{j};
        indx = strcmp({obj.m_registers.regName},str(2:end-1));
        if(sum(indx)==0)
            error('Constraints parse error: could not find register %s',str(2:end-1));
        end
        if(obj.m_registers(indx).autogen==-1)
            %autogen register with non calculated value
            line=[];
            break;
        end

         line = strrep(line,str,['[' num2str(FirmwareBase.sprivRegstruct2val(obj.m_registers(indx))) ']' ]);
        
    end
    if(isempty(line))
        %enters here if stumbeled in an uninitialized autogen register
        continue;
    end
    %check constraint
    try
    ok = eval(line);
    catch
        error('FIRMWARE:privConstraints:ConstraintFailed','bad constraint: %s\n',origLine);
    end
    if(~ok)
        error('FIRMWARE:privConstraints:ConstraintFailed','Constraint Failed: %s\n(%s)',origLine,line);
    end
    
end


end

