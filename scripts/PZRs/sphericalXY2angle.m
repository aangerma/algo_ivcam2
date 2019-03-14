function [angX,angY] = sphericalXY2angle(x,y,regs)

y = y-double(regs.DIGG.sphericalOffset(2));
y = y*2^12; % bitshift(yy,-12);
y = y/double(regs.DIGG.sphericalScale(2));
angyQ = y;

x = x*4;
x = x-double(regs.DIGG.sphericalOffset(1));
x = x*2^10; % bitshift(xx,-12+2);
x = x/double(regs.DIGG.sphericalScale(1));
angxQ = x;

angX = (angxQ + 2047)/regs.EXTL.dsmXscale - regs.EXTL.dsmXoffset;
angY = (angyQ + 2047)/regs.EXTL.dsmYscale - regs.EXTL.dsmYoffset;

figure; plot(angxQ,angyQ,'.-');
figure; plot(angX,angY,'.-');

end

