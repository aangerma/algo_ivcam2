function xyQout = ranger( x,y,regs)
shift=double(regs.DIGG.bitshift);
% shift = double(regs.DIGG.bitshift);
xs=shift-2;
ys=shift;

x = bitshift(x+2^(xs-1),-xs);
y = bitshift(y+2^(ys-1),-ys  );

xq = min(max(int16(x),-2^14),2^14-1);% 15b
yq = min(max(int16(y),-2^11),2^11-1);% 12b
xyQout = [xq yq]';

end

