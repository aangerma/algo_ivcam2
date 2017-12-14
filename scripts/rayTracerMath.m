clear
%patch points
symbolic=true;
if(symbolic)
pa=sym('pa',[3 1],'real');
pb=sym('pb',[3 1],'real');
pc=sym('pc',[3 1],'real');
tx=sym('tx',[3 1],'real');%tx ray
rx=sym('rx',[3 1],'real');%tx ray
else
     rng(1);
    pa=rand(3,1);
    pb=rand(3,1);
    pc=rand(3,1);
    tx=rand(3,1);tx=tx/norm(tx);
    rx=-[rand;0;0];rx = rx/norm(rx);
end
%patch normal
n=cross(pb-pa,pc-pa);
n = n/norm(n);
%tx reflection
txR=tx-2*dot(n,tx)*n;

ang = acos(dot(txR,rx));
att = cos(ang)^2;
if(symbolic)
c=collect(att,[pa pb pc]);
else
    %%
    plotv = @(va,vb,varargin) quiver3(va(1),va(2),va(3),vb(1),vb(2),vb(3),0,varargin{:});
    clf;
    hold on
    plotv([0 0 0],tx,'-b');
    plotv(tx,n,'r');
    plotv(tx,txR,'-.b');
    plotv(tx,rx,'g');
    text(rx(1)+tx(1),rx(2)+tx(2),rx(3)+tx(3),num2str(att))
    hold off
    axis equal
    grid on
end





