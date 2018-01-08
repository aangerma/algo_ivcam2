function [v,r]=z16toVerts(zUINT16,regs)


[sinx,cosx,~,~,sinw,cosw,~]=Pipe.DEST.getTrigo(size(zUINT16),regs);
 
    


% [nyi,nxi]=ndgrid((1:h)/h*2-1,(1:w)/w*2-1);
% 
% phi   = atand(tand(regs.FRMW.xfov/2).*nxi);
% theta = atand(tand(regs.FRMW.yfov/2).*nyi);
z = double(zUINT16)/bitshift(1,regs.GNRL.zMaxSubMMExp);
z(zUINT16==0)=nan;

r = z./(cosx.*cosw);
x = z.*sinx./cosx;
y = z.*sinw./(cosw.*cosx);

v = cat(3,x,y,z);
end


