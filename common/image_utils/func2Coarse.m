function [imout,imoutSmall]=func2Coarse(func,imin,ksz)
imout=zeros(size(imin));
imoutSmall=zeros(floor(size(imin)./ksz));
m2v = @(v) v(:);
for xs=1:ksz(2):size(imin,2)
    for ys=1:ksz(1):size(imin,1)
        xe = min(xs+ksz(2),size(imin,2));
        ye = min(ys+ksz(1),size(imin,1));
        v = func(m2v(imin(ys:ye,xs:xe)));
        imout(ys:ye,xs:xe)=v;
        imoutSmall(ceil(ys/ksz(1)),ceil(xs/ksz(2)))=v;
    end
end
end