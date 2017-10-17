function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)


autogenRegs.JFIL.sort1iWeightsC = uint16(256-sum(regs.JFIL.sort1iWeights)*2);
autogenRegs.JFIL.sort2iWeightsC = uint16(256-sum(regs.JFIL.sort2iWeights)*2);
autogenRegs.JFIL.sort3iWeightsC = uint16(256-sum(regs.JFIL.sort3iWeights)*2);

autogenRegs.JFIL.sort1dWeightsC = uint16(256-sum(regs.JFIL.sort1dWeights)*2);
autogenRegs.JFIL.sort2dWeightsC = uint16(256-sum(regs.JFIL.sort2dWeights)*2);
autogenRegs.JFIL.sort3dWeightsC = uint16(256-sum(regs.JFIL.sort3dWeights)*2);

autogenRegs.JFIL.nnNorm    =  single(bitshift(regs.FRMW.nnMaxRange,regs.GNRL.zMaxSubMMExp))^-1;
autogenRegs.JFIL.nnNormInv =  single(bitshift(regs.FRMW.nnMaxRange,regs.GNRL.zMaxSubMMExp));


numValidsAroundInvalid = 1:8;
autogenRegs.JFIL.sortInvMultiplication = [0 uint16((1./numValidsAroundInvalid).*2^10) 0].';


%=======================================NN act func=======================================
t=-1:2/6:1;
% npno = @(x) (x-min(x))/(max(x)-min(x))*2-1;
% actFuncD = npno((1+exp(-regs.MTLB.dnnActFuncFactor*t)).^-1);
% actFuncI = npno((1+exp(-regs.MTLB.innActFuncFactor*t)).^-1);
%2017-06-17 due to RTL bug only to slope are available - for negative and positive inputs.
actFuncD = max(t,0)+regs.MTLB.dnnActFuncFactor*min(t,0);
actFuncI = max(t,0)+regs.MTLB.innActFuncFactor*min(t,0);
autogenRegs.JFIL.dnnActFunc = lineFit(actFuncD);
autogenRegs.JFIL.innActFunc = lineFit(actFuncI);

%=======================================JFIL - shading=======================================
[yg,xg]=ndgrid(0:16);

shadingLUT =min(2,((xg-7.5).^2+(yg-7.5).^2)*regs.FRMW.shadingCurve+1);
shadingLUT = uint16(round(shadingLUT*2047));
r0=shadingLUT(1,:);
dr=diff(int16(shadingLUT));
assert(max(abs(dr(:)))<2^9-1); %dr is saved in 10b signed
autogenRegs.JFIL.irShadingLUTr0 = [r0 0];
autogenRegs.JFIL.irShadingLUTdelta = vec(dr)';
w = regs.GNRL.imgHsize;
h = regs.GNRL.imgVsize;
if(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==1)
    w=w*2;
elseif(~regs.JFIL.upscalexyBypass && regs.JFIL.upscalex1y0==0)
    h=h*2;
end

autogenRegs.JFIL.irShadingScale = uint16(round(2^10*2^8./double([w h] )));

roundfix = (bitshift(uint32([w h]-1).*uint32(autogenRegs.JFIL.irShadingScale)+2^7,-8)>1023);
autogenRegs.JFIL.irShadingScale = autogenRegs.JFIL.irShadingScale - uint16(roundfix);




%=======================================JFIL - gamma LUT=======================================

X = linspace(0,1,65);
outLut = X.^(regs.FRMW.jfilGammaFactor);
autogenRegs.JFIL.gamma = uint8([outLut*(2^8-1) 0 0 0]);


regs = Firmware.mergeRegs(regs,autogenRegs);
end

function vout = lineFit( yIn)
y=Utils.fp20('to',(Utils.fp20('from',single(yIn))));
x =Utils.fp20('to',Utils.fp20('from',single(-1:2/6:1)));
a = diff(y)./diff(x);

b=y(1:end-1) - a.*x(1:end-1);
vout = (Utils.fp20('from',single([a b])));
end

