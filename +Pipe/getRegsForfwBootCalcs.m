function [outRegs,outLuts] = getRegsForfwBootCalcs(inRegs,inLuts,getMeta)
if(~exist('getMeta','var'))
    fw=Firmware;
    m=fw.getMeta();
else
    m=getMeta;
end
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
outLuts.FRMW.tmpTrans=inLuts.FRMW.tmpTrans; 

%% for pre calc and internal to run
outRegs.FRMW.preCalcBypass = inRegs.FRMW.preCalcBypass;
outRegs.MTLB=inRegs.MTLB; 
outRegs.EPTG=inRegs.EPTG;
if ~inRegs.FRMW.preCalcBypass
    % keep registers for jfilPreCalc
    outRegs.FRMW.nnMaxRange=inRegs.FRMW.nnMaxRange; 
    outRegs.FRMW.shadingCurve=inRegs.FRMW.shadingCurve; 
    outRegs.FRMW.jfilGammaFactor=inRegs.FRMW.jfilGammaFactor;

end



end




