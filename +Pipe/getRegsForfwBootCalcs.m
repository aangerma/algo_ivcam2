function [outRegs,outLuts] = getRegsForfwBootCalcs(inRegs,inLuts)

fw=Firmware;
m=fw.getMeta();

% group 0: = don't transfer, 1: from EPROM , 2: User config / other 

regs2write={m([m.TransferToFW]~='0').regName};


outRegs=struct;
for i=1:length(regs2write)
    [b,aname]=ConvertRegName2blockNameId (regs2write{i});
    if (isfield(inRegs,b))
        if(isfield(inRegs.(b),aname))            
            outRegs.(b).(aname)=inRegs.(b).(aname);
        end
    end
end


outLuts.DIGG.undistModel=inLuts.DIGG.undistModel;





end


function [b,aname,sb]=ConvertRegName2blockNameId (blkDataName)
sb = nan;
b = blkDataName(1:4);
[bi,ei]=regexp(blkDataName,'_(?<num>[\d]+)');
if(~isempty(bi) && ei==length(blkDataName))
    sb = str2double(blkDataName(bi+1:ei));
    aname = blkDataName(5:bi-1);
else
    aname = blkDataName(5:end);
end

end