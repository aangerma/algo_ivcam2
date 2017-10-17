function [ confOut ] = confBlock( dutyCycle4b, psnr6b, maxPeak6b,ir,  regs )
%%
%  regs.DEST.confactIn = auxpt2x0dxS(0,0,63,15);
%  regs.DEST.confactOt = auxpt2x0dxUS(0,0,15,15);

a1 = int16(bitshift(uint16(dutyCycle4b),2));
a2 = int16(psnr6b);
a3 = int16(maxPeak6b);
a4 = int16(min(2^6-1,bitshift(ir,-double(regs.DEST.confIRbitshift))));
w1 = int16(regs.DEST.confw1);
v  = int16(regs.DEST.confv);
r1 = a1*w1(1)+a2*w1(2)+a3*w1(3)+a4*w1(4) + v(1);
r1 = actFuncS(r1,regs.DEST.confactIn);
w2 = int16(regs.DEST.confw2);

r2 = a1*w2(1)+a2*w2(2)+a3*w2(3)+a4*w2(4) + v(2);
r2 = actFuncS(r2,regs.DEST.confactIn);
q  = int16(regs.DEST.confq); %2x8bit
r  = int16(r1)*q(1)+int16(r2)*q(2) + v(3);
confOut = actFuncUS(r,regs.DEST.confactOt);
confOut = bitshift(confOut,-4);
confOut = max(confOut,1);

end

function [actOut]= actFuncS ( input, p )
%input  - 16bit signed
%output -  8bit signed
x0 = int32(p(1));
dt = int32(typecast(p(2),'uint16'));
actOut =int8(((int32(input)-x0)*255)/dt-128);
end

function [actOut]= actFuncUS ( input, p )
%input  - 16bit signed
%output -  8bit unsigned
x0 = int32(p(1));
dt = int32(typecast(p(2),'uint16'));
actOut =uint8(((int32(input)-x0)*255)/dt);
end


function outRegs = auxpt2x0dxS(x0,y0,x1,y1) %#ok
a = (y1-y0)/(x1-x0);
b = y0-a*x0;
t0 = (-128-b)/a;
dt = 255/a;
outRegs = int16([t0 dt]);
disp([dec2hex(typecast(outRegs(1),'uint16'),4) dec2hex(typecast(outRegs(2),'uint16'),4)]);
end

function outRegs = auxpt2x0dxUS(x0,y0,x1,y1)%#ok
a = (y1-y0)/(x1-x0);
b = y0-a*x0;
t0 = (0-b)/a;
dt = 255/a;
outRegs = int16([t0 dt]);
disp([dec2hex(typecast(outRegs(1),'uint16'),4) dec2hex(typecast(outRegs(2),'uint16'),4)]);
end