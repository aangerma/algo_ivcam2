function [EPROMtable,ConfigTable,CbufXsections,DiggGammaTable] = generateTablesForFw(obj,outputFldr)

obj.get();
m=obj.getMeta();

EPROMtable=m([m.TransferToFW]=='1');
ConfigTable=m([m.TransferToFW]=='2');
CbufXsections=m([m.TransferToFW]=='3');
DiggGammaTable=m([m.TransferToFW]=='4');
EPROmaxTableSize=496;

if(exist('outputFldr','var'))
    writetable(struct2table(EPROMtable), strcat(outputFldr,'/EPROMtable.xlsx'))
    writetable(struct2table(ConfigTable), strcat(outputFldr,'/ConfigTable.xlsx'))
    writetable(struct2table(CbufXsections), strcat(outputFldr,'/CbufSectionsTable.xlsx'))

    [EPROMtableSize]=calcTableSize(struct2table(EPROMtable));
    writeTableTobin(EPROMtableSize,EPROmaxTableSize-EPROMtableSize,struct2table(EPROMtable),strcat(outputFldr,'\Algo_Calibration_Info.bin'));
    
    CBUFtableSize=EPROmaxTableSize;
    writeTableTobin(CBUFtableSize,0,struct2table(CbufXsections),strcat(outputFldr,'\CBUF_Calibration_Info.bin'));

    obj.writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep,['DIGG_Undist_Info'  '.bin']),true);
    obj.writeLUTbin(obj.getAddrData('FRMWtmpTrans'),fullfile(outputFldr,filesep,['FRMW_tmpTrans_Info'  '.bin']),true);
end
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
        case {'logical'}
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
            
        case {'b'}
            type='uint8';
            value=str2double(DataTable.value{i});
        otherwise
            error('wirte table to bin: undifiend base');
    end

    s.setNext(value,type);
end


binTable = s.flush();


fileID = fopen(fname,'w');
fwrite(fileID,binTable','uint8');
fclose(fileID);


end
