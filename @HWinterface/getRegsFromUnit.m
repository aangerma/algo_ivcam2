function [regs,luts ] = getRegsFromUnit( obj, fname,verbose)
%GETREGSFROMUNIT reads the regs from the unit (those that can be
%read) and also writes their values into 
if ~exist('verbose','var')
    verbose = 0;
end 
fw = Firmware;
m = fw.getMeta();
tablesFolder = [ivcam2root filesep '+Pipe' filesep 'tables']; 
lutdata = fw.sprivReadCSV([tablesFolder filesep 'lutsDefinitions.frmw']);
lutdata =lutdata(2:end,:);

% Read all regs and luts
filters = {'GNRL';'DIGG';'RAST';'DCOR';'DEST';'CBUF';'JFIL';'EXTL'};

if exist('fname','var')
    fileID = fopen(fname,'w');
end
for i = 1:numel(m)
%     if isempty(strfind(m(i).regName,'EPT')) && isempty(strfind(m(i).regName,'MTLB')) && isempty(strfind(m(i).regName,'FRMW')) && isempty(strfind(m(i).regName,'EPTG')) && isempty(strfind(m(i).regName,'STAT')) && isempty(strfind(m(i).regName,'EXTLcorSaturationPrc'))
%        fprintf('Collected: %d %s\n',i,m(i).regName);
%        [~,devVal] = hw.cmd(sprintf('mrd %08x %08x',m(i).address(1),m(i).address(1)+4) );
%        str = sprintf('mwd %08x %08x %08x // %s\n',m(i).address(1),m(i).address(1)+4,devVal,m(i).regName);
%        fprintf(fileID,str);
%     else
%        fprintf('Skipped: %d %s\n',i,m(i).regName);
%     end
    regname = m(i).regName;
    if strcmp(regname,'RASTsharedDenom')
       xxx = 1; 
    end
    passedFilters = false;
    for f = 1:numel(filters)
        passedFilters = passedFilters || startsWith(regname,filters{f});
    end
    if ~passedFilters
       continue; 
    end
    
    underscore = strfind(regname,'_');
    
    if isempty(underscore)
        regValue = obj.read(regname);
        regs.(regname(1:4)).(regname(5:end)) = regValue;
        if exist('fname','var')
            str = sprintf('%-30s, %8x, %9s\n',regname,m(i).address,dec2hex(regValue));
            if verbose
                fprintf(str);
            end
            fprintf(fileID,str);
        end
    else
        if contains(regname,'_000')
            value = obj.read(regname(1:underscore-1));
            regs.(regname(1:4)).(regname(5:underscore-1)) = value;
            for k = 1:numel(value)
                regFullName = sprintf('%s_%03d',regname(1:underscore-1),k-1);
                
                if exist('fname','var')
                    str = sprintf('%-30s, %8x, %9s\n',regFullName,m(i).address+4*(k-1),dec2hex(value(k)));
                    if verbose
                        fprintf(str);
                    end
                    fprintf(fileID,str);
                end
            end
        end
        
        
    end

    


end

for i = 1:size(lutdata,1)
    currlut = lutdata(i,:);
    
    lname = currlut{1};
    passedFilters = false;
    for f = 1:numel(filters)
        passedFilters = passedFilters || startsWith(lname,filters{f});
    end
    if ~passedFilters
       continue; 
    end
    value = obj.read(lname); 
    luts.(lname(1:4)).(lname(5:end)) = value;
    if exist('fname','var')
        for k = 0:numel(value)-1
            str = sprintf('%-30s, %8x, %9s\n',sprintf('%s_%04d',lname,k),str2num(currlut{2})+4*k,dec2hex(value(k+1)));
            if verbose
                fprintf(str);
            end
            fprintf(fileID,str);
        end
    end
    
end




if exist('fname','var')
    fclose(fileID);
end



end

