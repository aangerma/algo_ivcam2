function [EPROMtable,ConfigTable] = generateTablesForFw(obj,outputFldr)

obj.get(); 
m=obj.getMeta();

EPROMtable=m([m.TransferToFW]=='1');
ConfigTable=m([m.TransferToFW]=='2');

writetable(struct2table(EPROMtable), strcat(outputFldr,'/EPROMtable.xlsx'))
writetable(struct2table(ConfigTable), strcat(outputFldr,'/ConfigTable.xlsx'))


obj.writeLUTbin(obj.getAddrData('DIGGundistModel'),fullfile(outputFldr,filesep,['DIGG_Undist_Info'  '.bin']),true);
obj.writeLUTbin(obj.getAddrData('FRMWtmpTrans'),fullfile(outputFldr,filesep,['FRMW_tmpTrans_Info'  '.bin']),true);

end

