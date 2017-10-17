function genDIGGgamma(doUpdate)
%% Generate a LUT for gamma function.
% if(~exist('doUpdate','var'))
%     doUpdate=false;
% end
% 1. 12 bits in.
% 2. 12 bits out.
% 3. 64 values.
GAMMA = 1;
X_MIN = 600;
X_MAX = 2000;
scaleIn =round(4095/(X_MAX-X_MIN)*2^10)
shiftIn = -round(X_MIN*4095/(X_MAX-X_MIN));
scaleOt = 2^10;
shiftOt = 0;
regs.DIGG.gammaScale = int16([scaleIn scaleOt]);
regs.DIGG.gammaShift = int16([shiftIn shiftOt]);
% 
% X = linspace(0,1,65);
% outLut = X.^(GAMMA);
% outLut = outLut*(2^12-1);
% regs.DIGG.gamma=uint16(outLut);

fw=Firmware;
fw.setRegs(regs,[]);
fw.disp('DIGGgammaScale|DIGGgammaShift');

% 
% plot(X*4095,outLut);
% rectangle('pos',[0 0 4095 4095]);
% xlabel('Input');
% ylabel('output');
% axis equal;
% grid on
% grid minor
% lut.data = outLut;
% lut.block = 'DIGG';
% lut.name = 'gamma';
% if(doUpdate)
%     setLUTdata(lut);
% end

end

