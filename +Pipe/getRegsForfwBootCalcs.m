function [outRegs,outLuts] = getRegsForfwBootCalcs(inRegs,inLuts)

fw=Firmware;
m=fw.getMeta();

% group 0: = don't transfer, 1: from EPROM , 2: User config / other 

MetaForFW=m([m.TransferToFW]~='0');
RegsNum=length(MetaForFW); 
outRegs=struct;
for i=1:RegsNum
    metareg=MetaForFW(i); 
    if (isfield(inRegs,metareg.algoBlock))
        if(isfield(inRegs.(metareg.algoBlock),metareg.algoName))            
            outRegs.(metareg.algoBlock).(metareg.algoName)=inRegs.(metareg.algoBlock).(metareg.algoName);
        end
    end
end


outLuts.DIGG.undistModel = inLuts.DIGG.undistModel;



end




