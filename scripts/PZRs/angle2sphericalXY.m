function [x,y] = angle2sphericalXY(angX,angY,regs)

angxQ = (angX+regs.EXTL.dsmXoffset)*regs.EXTL.dsmXscale - 2047;
angyQ = (angY+regs.EXTL.dsmYoffset)*regs.EXTL.dsmYscale - 2047;
%figure; plot(angX, angY, '.-');
%figure; plot(angxQ,angyQ,'.-');

x = double(angxQ);
x = x*double(regs.DIGG.sphericalScale(1));
x = x/2^10; % bitshift(xx,-12+2);
x = x+double(regs.DIGG.sphericalOffset(1));
x = x/4;

y = double(angyQ);
y = y*double(regs.DIGG.sphericalScale(2));
y = y/2^12; % bitshift(yy,-12);
y = y+double(regs.DIGG.sphericalOffset(2));

end

