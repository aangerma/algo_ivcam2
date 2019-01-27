function [regs,autogenRegs,autogenLuts] = fwBootCalcs(regs,luts,autogenRegs,autogenLuts)
%% =======================================DCOR - Input registers ==============================================
% register input            %   source conf/cal/Autogen
%==============================================================================================================
% GNRL.imgVsize             %   conf
% GNRL.tmplLength           %   Auto gen
% DCOR.bypass               %   conf
% DEST.bypass               %   conf

%% =======================================DCOR - output Auto gen registers ====================================
% register output            %   description
%%==============================================================================================================
% RAST.cmaBinSize           %  auto gen
% RAST.sharedDenomExp       %  auto gen 
% RAST.sharedDenom          %  auto gen
% RAST.cmaMaxSamples        %  auto gen
% RAST.dcCodeNorm           %  auto gen
% RAST.cma64cntrsOnly       %  auto gen
% RAST.cmaMemMode           %  auto gen
% RAST.cmaFiltMode          %  auto gen
% RAST.cmacCycPerValid      %  auto gen
% RAST.cmaNumOfBinsOvrd     %  auto gen
% RAST.cmaFiltMode          %  auto gen

binSize3=...
regs.GNRL.imgVsize > 240 & regs.GNRL.imgVsize <= 480 & regs.GNRL.tmplLength > 476 & regs.GNRL.tmplLength <= 832 |...
regs.GNRL.imgVsize > 480 & regs.GNRL.imgVsize <= 960 & regs.GNRL.tmplLength > 230 & regs.GNRL.tmplLength <= 416;
if(binSize3)
autogenRegs.RAST.cmaBinSize = uint8(3);
else
autogenRegs.RAST.cmaBinSize = uint8(5);
end
%3:6
denomDiv = double(regs.GNRL.tmplLength)./[8 16 32 64];
dInv = find(rem(denomDiv,1)==0,1,'last');
if(isempty(dInv))
%     Illegal code length
    dInv=1;
end
autogenRegs.RAST.sharedDenomExp=uint8(dInv+2);

autogenRegs.RAST.sharedDenom = 2^autogenRegs.RAST.sharedDenomExp;
autogenRegs.RAST.cmaMaxSamples = 2^autogenRegs.RAST.cmaBinSize-1;


dcCodeNorm = uint16(single(2^22)/single(regs.GNRL.tmplLength));
autogenRegs.RAST.dcCodeNorm = dcCodeNorm;

%codeNorm =typecast(newRegs.RAST.dcCodeNorm,'uint64');
%codeNorm = newRegs.RAST.dcCodeNorm;

%------------ASIC REGS--------------
autogenRegs.RAST.cma64cntrsOnly = uint32(0);
autogenRegs.RAST.cmaMemMode =  uint32(0);
autogenRegs.RAST.cmaFiltMode =uint32(0);
autogenRegs.RAST.cmacCycPerValid = uint32(256);
autogenRegs.RAST.cmaNumOfBinsOvrd =uint32(0);
if(regs.DCOR.bypass   &&  regs.DEST.bypass)
    autogenRegs.RAST.cmaNumOfBinsOvrd =uint32(1);
end

if (regs.GNRL.imgVsize <=240 && ~binSize3  && regs.GNRL.tmplLength <= 2048)
    autogenRegs.RAST.cmaMemMode = uint32(2);
end
if (regs.GNRL.imgVsize <=480 && binSize3  && regs.GNRL.tmplLength <= 954)
    autogenRegs.RAST.cmaMemMode = uint32(1);
end
if (regs.GNRL.imgVsize >240 && regs.GNRL.imgVsize <=480 && ~binSize3 && regs.GNRL.tmplLength <= 477)
    autogenRegs.RAST.cmaMemMode = uint32(1);
end
if (regs.GNRL.imgVsize >480 && binSize3  && regs.GNRL.tmplLength < 460)
    autogenRegs.RAST.cmaMemMode = uint32(0);
    autogenRegs.RAST.cma64cntrsOnly = uint32(1);
end
if (regs.GNRL.imgVsize >480 && ~binSize3  && regs.GNRL.tmplLength < 230)
    autogenRegs.RAST.cmaMemMode = uint32(0);
    autogenRegs.RAST.cma64cntrsOnly = uint32(1);
end
if (regs.GNRL.tmplLength>512)
    autogenRegs.RAST.cma64cntrsOnly = uint32(0);
end

if(regs.GNRL.imgVsize<=960 &&regs.GNRL.tmplLength<=416 && binSize3 ) 	  , autogenRegs.RAST.cmaFiltMode = uint32(1);
elseif (regs.GNRL.imgVsize<=960 && regs.GNRL.tmplLength<=256)             , autogenRegs.RAST.cmaFiltMode = uint32(2);
elseif(regs.GNRL.imgVsize<=480  && regs.GNRL.tmplLength<=832 && binSize3 ), autogenRegs.RAST.cmaFiltMode  = uint32(3);
elseif(regs.GNRL.imgVsize<=480 &&regs.GNRL.tmplLength<=496)     		  , autogenRegs.RAST.cmaFiltMode = uint32(4);
elseif(regs.GNRL.imgVsize<=240 &&regs.GNRL.tmplLength<=1024  )    		  , autogenRegs.RAST.cmaFiltMode = uint32(6);
end

switch(autogenRegs.RAST.cmaFiltMode)
case {1,2}, autogenRegs.RAST.cmacCycPerValid=calcMinReqdClksDCOR( 256,regs.GNRL.sampleRate,regs.FRMW.coarseSampleRate,regs.GNRL.tmplLength);
case {3,4}, autogenRegs.RAST.cmacCycPerValid=calcMinReqdClksDCOR( 512,regs.GNRL.sampleRate,regs.FRMW.coarseSampleRate,regs.GNRL.tmplLength);
case 6    , autogenRegs.RAST.cmacCycPerValid=calcMinReqdClksDCOR(1024,regs.GNRL.sampleRate,regs.FRMW.coarseSampleRate,regs.GNRL.tmplLength);
otherwise , autogenRegs.RAST.cmacCycPerValid=calcMinReqdClksDCOR(7936,regs.GNRL.sampleRate,regs.FRMW.coarseSampleRate,regs.GNRL.tmplLength);
end

if(~regs.JFIL.upscalexyBypass && regs.CBUF.bypass &&  autogenRegs.RAST.cmacCycPerValid<512)
    autogenRegs.RAST.cmacCycPerValid = uint32(512);
end




autogenRegs.RAST.lnBufCycPerValid = autogenRegs.RAST.cmacCycPerValid;

regs = Firmware.mergeRegs(regs,autogenRegs);

end

function mv=calcMinReqdClksDCOR(min_val,sampleRate,coareSampleRate,tmplLen)

dec_ratio = sampleRate / coareSampleRate;
crse_corr = double(tmplLen) / double(dec_ratio);

cma_drv_clks  = ceil(double(tmplLen) / 84.0);
cor_calc_clks = ceil(crse_corr / 66.0) * ceil(crse_corr / 22.0);
if(tmplLen == 2048)
    min_reqd_clks = 150;
else
    min_reqd_clks = iff(cma_drv_clks > cor_calc_clks, cma_drv_clks ,cor_calc_clks);
    min_reqd_clks = ceil(min_reqd_clks / 5.0) * 5;
end
cyc_per_valid_new_val= bitshift(uint16(min_reqd_clks)/5,8);

if(cyc_per_valid_new_val>min_val)
    mv= uint32(cyc_per_valid_new_val);
else
    mv= uint32(min_val);
end
end
