function values = sprivReadConfigurationFile(filename)


[~,~,ext]=fileparts(filename);
switch(lower(ext))
    case '.csv'
        allData = FirmwareBase.sprivReadCSV(filename);
    otherwise
        error('unsupported filetype');
end

if(isempty(allData))
    values = [];
    return;
end
if(size(allData,2)==1)
    %compact format
    headers = {'regName','base','value'};
    data=cellfun(@(x) strsplit(x,{' ' char(9)}),allData,'uni',0);
    if(~all(cellfun(@(x) length(x),data)==2))
        error('Bad format (%s)',cell2str(data{find(cellfun(@(x) length(x),data)~=2,1)}));
    end
    data=cellfun(@(x) {x{1} x{2}(1) x{2}(2:end)},data,'uni',0);
    data=reshape([data{:}],3,[])';
    if(~all(cellfun(@(x) any(x=='bsdhf'),data(:,2))))
        error('Bad value base (%s)',cell2str(data(cellfun(@(x) ~any(x=='bsdhf'),data(:,2)),:)));
    end
    
    
else
    headers = allData(1,:);
    data = allData(2:end,:);
end




headers = cellfun(@(x) strrep(strrep(x,')','_'),'(','_'),headers,'uni',false);

regNameInd = find(strcmp(headers,'regName'));
if(isempty(regNameInd))
    error('Header row must containt regName');
end
if(isempty(find(strcmp(headers,'base'), 1)))
    error('Header row must containt base');
end
if(isempty(find(strcmp(headers,'value'), 1)))
    error('Header row must containt value');
end

badDtaLen = cellfun(@(x) length(x),data(:,regNameInd))<5;
if(any(badDtaLen))
    error('register name should be atleeast 5 characters long (%s,line %d)',data{find(badDtaLen,1),regNameInd},regNameInd)
end


%remove Regs suffix (if exists)
regsSuffix = strcmp(cellfun(@(x) x(1:4),data(:,regNameInd),'uni',false),'Regs');
data(regsSuffix,regNameInd)= cellfun(@(x) x(5:end),data(regsSuffix,regNameInd),'uni',false);

%check uniquness
uniqueRegNames  = unique(data(:,regNameInd));
a=cellfun(@(x)  sum(strcmp(data(:,regNameInd),x)),uniqueRegNames);
if(any(a~=1))
    error('Register appears in defaults file more than once (%s)',uniqueRegNames{find(a~=1,1)});
end

%% table2struct
evl = sprintf('headers{%d},data(:,%d),',repmat(1:length(headers),2,1));
%updated field is for external field update
evl=['struct(' evl(1:end-1) ' );'];
values=eval(evl);
if(~isfield(values,'comments'))
    values=arrayfun(@(x) setfield(x,'comments',''),values); 
end
if(~isfield(values,'uniqueID'))
    values=arrayfun(@(x) setfield(x,'comments','000.000.000'),values); 
end

end

