function [updatedConfigTable,diffTable] = createConfigTableForAllSkus()
%%
current_dir = mfilename('fullpath');
ix = strfind(current_dir, '\');

%% L515 vga
pathVga=fullfile(current_dir(1:ix(end-1)), '\releaseConfigCalibVGA');
[ConfigTableVga] = GetConfigTable(pathVga);

regName={ConfigTableVga.regName}';
type={ConfigTableVga.type}';
arraySize={ConfigTableVga.arraySize}';

VGAbase={ConfigTableVga.base}';
VGAvalue={ConfigTableVga.value}';
%% L515 xga
pathXGA=fullfile(current_dir(1:ix(end-1)), '\releaseConfigCalibXGA');
[ConfigTableXga] = GetConfigTable(pathXGA);

XGAbase={ConfigTableXga.base}';
XGAvalue={ConfigTableXga.value}';

%% L520
pathL520=fullfile(current_dir(1:ix(end-1)), '\releaseConfigCalibL520');
[ConfigTableL520] = GetConfigTable(pathL520);

L520base={ConfigTableL520.base}';
L520value={ConfigTableL520.value}';

%% full table
mergedTable=table(regName,type,arraySize,VGAbase,VGAvalue,XGAbase,XGAvalue,L520base,L520value);
ConfigPath=fullfile(current_dir(1:ix(end-1)), '\+configurationStructure');
[updatedConfigTable,version,TableIsUpdated]= updateConfigTable(ConfigPath,mergedTable);
%% diff table
inds=find(~strcmp(updatedConfigTable.VGAvalue,updatedConfigTable.XGAvalue) | ~strcmp(updatedConfigTable.VGAvalue,updatedConfigTable.L520value));
diffTable=mergedTable(inds,:);
end

function [ConfigTable] = GetConfigTable(ConfigPath)
fw=Pipe.loadFirmware(ConfigPath);
fw.get();
m=fw.getMeta();
ConfigTable=m([m.TransferToFW]=='2');
end

function [updatedConfigTable,version,TableIsUpdated]= updateConfigTable(ConfigPath,newConfigTable)
%% read latest config structure
path= fullfile(ConfigPath,'configVersions');
files=dir([path,'\config*.csv']); filesNames=sort({files.name});
[LatestVersion]= getFileVersion(filesNames{end});

updatedStructure=0; updatedValues=0;

ConfigLatestVersion=readtable([path,'\',filesNames{end}]);

%% check for structure change and update
originNameVec=ConfigLatestVersion.regName;
newNameVec=newConfigTable.regName;
i=1;
Lorig=length(originNameVec); Lnew=length(newNameVec);
while(i<=Lorig || i<=Lnew)
    if (i>Lorig) % addition at the end
        originNameVec=[originNameVec(1:end);newNameVec(i)] ;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        i=i+1;
        updatedStructure=1;
        continue;
    end
    if (i>Lnew) % delition at the end
        originNameVec=originNameVec(1:end-1);
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        i=i+1;
        updatedStructure=1;
        
        continue;
    end
    if strcmp(originNameVec{i},newNameVec{i})
        i=i+1;
        continue;
    end
    % addition of new line
    if(sum(strcmp(newNameVec{i},originNameVec))==0) % new name isn't exist at originNameVec
        originNameVec=[originNameVec(1:end);newNameVec(i)] ;
        newConfigTable=[newConfigTable(1:i-1,:) ; newConfigTable(i+1:end,:) ; newConfigTable(i,:)];
        newNameVec=newConfigTable.regName;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        updatedStructure=1;
        continue;
        % deleteion of old line
    elseif(sum(strcmp(originNameVec{i},newNameVec))==0)
        newLine=newConfigTable(i,:);
        newLine.regName={'Reserved'};
        newLine.VGAbase={'h'}; newLine.XGAbase={'h'};newLine.L520base={'h'};
        newLine.VGAvalue={'0'};newLine.XGAvalue={'0'};newLine.L520value={'0'};
        newConfigTable=[newConfigTable(1:i-1,:);newLine;newConfigTable(i:end,:)] ;
        newNameVec=newConfigTable.regName;
        originNameVec=[newNameVec(1:i-1,:);newLine.regName;newNameVec(i+1:end,:)] ;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        updatedStructure=1;
        
    end
    i=i+1;
end

TableIsUpdated=1; 
if updatedStructure % update major version
    version=LatestVersion+1;
else
    % check if value has changed
    if (sum(~strcmp(ConfigLatestVersion.VGAvalue,newConfigTable.VGAvalue))~=0 ...
            || sum(~strcmp(ConfigLatestVersion.XGAvalue,newConfigTable.XGAvalue))~=0 ...
            || sum(~strcmp(ConfigLatestVersion.L520value,newConfigTable.L520value))~=0)
        updatedValues=1;
        version=LatestVersion+0.01;
        writetable(newConfigTable,path);
    end
    warning('Configuration table is identical to previous version');
    version=LatestVersion; 
    TableIsUpdated=0; 
end

if (updatedValues || updatedStructure)
    txtVer=num2str(version);
    txtVer=strrep(txtVer,'.','_');
    writetable(newConfigTable,[path,'configVer',txtVer,'.csv']);
end
updatedConfigTable=newConfigTable;

end


function [ver]= getFileVersion(fileName)
ver=strsplit(fileName,'Ver'); ver=ver{2}; ver=strsplit(ver,'.'); ver=ver{1};
ver=strrep(ver,'_','.'); ver=str2double(ver);
end