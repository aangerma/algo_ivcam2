function [verts,r]=z16toVerts(zUINT16,regs)

sz=size(zUINT16);
z = double(zUINT16)/bitshift(1,regs.GNRL.zMaxSubMMExp);
z(zUINT16==0)=nan;
[v,u]=ndgrid(0:sz(1)-1,0:sz(2)-1);

matK=reshape([typecast(regs.DCOR.spare,'single') 1],3,3)';
matKi=matK^-1;
tt=z(:)'.*[u(:)';v(:)';ones(1,numel(v))];
verts=reshape((matKi*tt)',[sz 3]);
r=sqrt(sum(verts.^2,3));






end


