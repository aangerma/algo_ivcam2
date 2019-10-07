function [EPROMtable,ConfigTable,CbufXsections,DiggGammaTable] = generateTablesForFw(obj,outputFldr,only_Algo_Calibration_Info,skip_algo_thermal_calib)
if ~exist('only_Algo_Calibration_Info','var')
    only_Algo_Calibration_Info = 0;
end
if ~exist('skip_algo_thermal_calib','var')
    skip_algo_thermal_calib = 0;
end


regs = obj.get();
m=obj.getMeta();
ver = typecast(regs.FRMW.calibVersion,'single');
v1= floor(ver);
v2= floor(mod(ver*100,100));
postfix = sprintf('_Ver_%02d_%02d.',v1,v2);
postfixThermal = sprintf('_Ver_%02d_%02d.',4,v2);
if(v1==0)
   warning('version is set to default value 0');  
end
EPROMtable=m([m.TransferToFW]=='1');
ConfigTable=m([m.TransferToFW]=='2');
CbufXsections=m([m.TransferToFW]=='3');
DiggGammaTable=m([m.TransferToFW]=='4');
txPWRpdTable=m([m.TransferToFW]=='6');
EPROmaxTableSize=496;
% EEPROMVersion=EPROMtable(find(strcmp({EPROMtable.algoName},'eepromVersion'))).value;
EPROMtable=updateEEPROMstructure(obj,struct2table(EPROMtable));
if(exist('outputFldr','var'))
    mkdirSafe(outputFldr);
    if only_Algo_Calibration_Info
        [EPROMtableSize]=calcTableSize(struct2table(EPROMtable));
        writeTableTobin(EPROMtableSize,EPROmaxTableSize-EPROMtableSize,struct2table(EPROMtable),fullfile(outputFldr,sprintf('Algo_Calibration_Info_CalibInfo%sbin',postfix)));
    
        return
    end
    
    writetable(struct2table(EPROMtable), strcat(outputFldr,'/EPROMtable.csv'))
    writetable(struct2table(ConfigTable), strcat(outputFldr,sprintf('/ConfigTable%scsv',postfix)))
    writetable(struct2table(CbufXsections), strcat(outputFldr,'/CbufSectionsTable.csv'))
    
    [EPROMtableSize]=calcTableSize(struct2table(EPROMtable));
    writeTableTobin(EPROMtableSize,EPROmaxTableSize-EPROMtableSize,struct2table(EPROMtable),fullfile(outputFldr,sprintf('Algo_Calibration_Info_CalibInfo%sbin',postfixThermal)));
    
    CBUFtableSize=EPROmaxTableSize;
    writeTableTobin(CBUFtableSize,0,struct2table(CbufXsections),fullfile(outputFldr,sprintf('CBUF_Calibration_Info_CalibInfo%sbin',postfix)));
    
    undistfns=obj.writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep,['DIGG_Undist_Info_%d_CalibInfo' postfix 'bin']),true);
    
    gammafn =obj.writeLUTbin(obj.getAddrData('DIGGgamma_'),fullfile(outputFldr,filesep,['DIGG_Gamma_Info_CalibInfo' postfix 'bin']));
    
    %no room for undist3: concat it to gamma file
    data = [readbin(gammafn{1});readbin(undistfns{3})];
    writebin(gammafn{1},data);
    delete(undistfns{3});
    
    txPWRpdfn = obj.writeLUTbin(obj.getAddrData('DESTtxPWRpd_'),fullfile(outputFldr,filesep,['DEST_txPWRpd_Info_CalibInfo' postfix 'bin']));
    
    obj.writeLUTbin(obj.getAddrData('FRMWtmpTrans'),fullfile(outputFldr,filesep,['FRMW_tmpTrans_Info'  '.bin']),true);
    if ~skip_algo_thermal_calib
        obj.writeAlgoThermalBin(fullfile(outputFldr,filesep,['Algo_Thermal_Loop_CalibInfo' postfixThermal 'bin']))
    end
end
end


function d=readbin(fn)
fid = fopen(fn,'r');
d=uint8(fread(fid,'uint8'));
fclose(fid);
end

function d=writebin(fn,d)
fid = fopen(fn,'w');
fwrite(fid,d,'uint8');
fclose(fid);
end
function [tableSize]=calcTableSize(table)
tableSize=0;
for i=1:size(table,1)
    type=table.type{i};
    switch type
        case {'uint32', 'int32','single'}
            s=4;
        case {'uint16' , 'int16'}
            s=2;
        case {'logical', 'uint8'}
            s=1;
        otherwise
            error('undifiend type');
    end
    tableSize=tableSize+s*table.arraySize(i);
end
end
function []=writeTableTobin(TableSize,resrevedLength,DataTable,fname)

%initialize the stream
arr = zeros(1,TableSize+resrevedLength,'uint8');
s = Stream(arr);

for i=1:size(DataTable,1)
    base=DataTable.base{i};
    type=DataTable.type{i};
    switch base
        case {'f','s','d'}
            value=str2double(DataTable.value{i});
        case {'h'}
            value=hex2dec(DataTable.value{i});
            if strcmp(type,'single')
                value=hex2single(DataTable.value{i});
            end
            if strcmp(type,'logical')
                type='uint8';
                value=str2double(DataTable.value{i});
            end
        case {'b'}
            type='uint8';
            value=str2double(DataTable.value{i});
        otherwise
            error('wirte table to bin: undifiend base');
    end
    switch type
        case 'int32'
            s.setNextInt32(typecast(uint32(value),'int32'));
        case 'int16'
            s.setNextInt16(typecast(uint16(value),'int16'));
        otherwise
            s.setNext(value,type);
    end
end


binTable = s.flush();


fileID = fopen(fname,'w');
fwrite(fileID,binTable','uint8');
fclose(fileID);


end

function [updatedEpromTable]= updateEEPROMstructure(obj,newEPROMtable)
% read latest eeprom structure
% read table (calibration. csv)
folder  = obj.gettableFolder();
path    = fullfile(obj.gettableFolder(),'eepromStructure.csv');
if ~exist(path,'file')
    current_dir = mfilename('fullpath');
    ix = strfind(current_dir, '\');
    folder=fullfile(current_dir(1:ix(end-1)-1), '\+Calibration\eepromStructure\');
    path =strcat(folder,'eepromStructure.csv');
end
updated=0;
EpromLatestVersion=readtable(path);
EpromLatestVersion.group=num2cell(EpromLatestVersion.group);
EpromLatestVersion.TransferToFW=num2cell(EpromLatestVersion.TransferToFW);
EpromLatestVersion.rangeStruct=num2cell(EpromLatestVersion.rangeStruct);


latestEEPROMVersion=hex2single(EpromLatestVersion(find(strcmp(EpromLatestVersion.algoName,'eepromVersion')),:).value);
originNameVec=EpromLatestVersion.regName;
newNameVec=newEPROMtable.regName;
i=1;
Lorig=length(originNameVec); Lnew=length(newNameVec);
while(i<=Lorig || i<=Lnew)
    if (i>Lorig) % addition at the end
        originNameVec=[originNameVec(1:end);newNameVec(i)] ;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        i=i+1;
        updated=1;
        continue;
    end
    if (i>Lnew) % delition at the end
        originNameVec=originNameVec(1:end-1);
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        i=i+1;
        updated=1;
        
        continue;
    end
    if strcmp(originNameVec{i},newNameVec{i})
        i=i+1;
        continue;
    end
    % addition of new line
    if(sum(strcmp(newNameVec{i},originNameVec))==0) % new name isn't exist at originNameVec
        originNameVec=[originNameVec(1:end);newNameVec(i)] ;
        newEPROMtable=[newEPROMtable(1:i-1,:) ; newEPROMtable(i+1:end,:) ; newEPROMtable(i,:)];
        newNameVec=newEPROMtable.regName;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        updated=1;
        continue;
        % deleteion of old line
    elseif(sum(strcmp(originNameVec{i},newNameVec))==0)
        newLine=newEPROMtable(i,:);
        newLine.regName={'Reserved'};
        newLine.algoName={'Reserved'};
        newLine.base={'h'};
        newLine.value={'0'};
        newEPROMtable=[newEPROMtable(1:i-1,:);newLine;newEPROMtable(i:end,:)] ;
        newNameVec=newEPROMtable.regName;
        originNameVec=[newNameVec(1:i-1,:);newLine.regName;newNameVec(i+1:end,:)] ;
        Lorig=length(originNameVec); Lnew=length(newNameVec);
        updated=1;
        
    end
    i=i+1;
end

vi=find(strcmp(EpromLatestVersion.algoName,'eepromVersion'));

if updated
    version=latestEEPROMVersion+0.01;
    newEPROMtable(vi,:).base={'h'};
    newEPROMtable(vi,:).value=single2hex(version);
    updatedEpromTable=table2struct(newEPROMtable);
    updatedEpromTable(vi).valueUINT32=obj.sprivRegstruct2uint32val(updatedEpromTable(vi));
    newEPROMtable(vi,:).valueUINT32=updatedEpromTable(vi).valueUINT32;
    writetable(newEPROMtable,path);
    save(strcat(folder,'eepromStructure.mat'),'updatedEpromTable');
else
    newEPROMtable(vi,:).value= EpromLatestVersion(vi,:).value;
    newEPROMtable(vi,:).base= EpromLatestVersion(vi,:).base;
    newEPROMtable(vi,:).value= EpromLatestVersion(vi,:).value;
    updatedEpromTable=table2struct(newEPROMtable);
    updatedEpromTable(vi).valueUINT32=obj.sprivRegstruct2uint32val(updatedEpromTable(vi));
    
end
end