function [verts,r]=z16toVerts(varargin)
%{
k=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';
z2mm=hw.read('GNRLzMaxSubMMExp');
z16=hw.getFrame(30).z;
v=Pipe.z16toVerts(z16,k,z2mm);
stlwriteMatrix('\\invcam450\D\temp\11.stl',v(:,:,1),v(:,:,2),v(:,:,3))

%}
    if(nargin==2)
        zUINT16=varargin{1};
        regs = varargin{2};
        z2mm=bitshift(1,regs.GNRL.zMaxSubMMExp);
        matK=reshape([typecast(regs.CBUF.spare,'single') 1],3,3)';
    elseif(nargin==3)
        zUINT16=varargin{1};
        matK=varargin{2};
        z2mm=varargin{3};
    else
        eror('incorrect number of input parameters');
    end
    
    sz=size(zUINT16);
    z = double(zUINT16)/double(z2mm);
    z(zUINT16==0)=nan;
    [v,u]=ndgrid(0:sz(1)-1,0:sz(2)-1);
    
    
    matKi=matK^-1;
    tt=z(:)'.*[u(:)';v(:)';ones(1,numel(v))];
    verts=reshape((matKi*tt)',[sz 3]);
    r=sqrt(sum(verts.^2,3));
    
    
    
    
    
    
end


