function a=plotLine(varargin)
abc = varargin{1};
abc=abc(:)';
abc = abc/sqrt(abc(1)^2+abc(2)^2);
a = gca;

yl = get(a,'ylim');
xl = get(a,'xlim');

tl = xl(1)+1j*yl(1);
tr = xl(2)+1j*yl(1);
bl = xl(1)+1j*yl(2);
br = xl(2)+1j*yl(2);



bot =abcFrompts(bl,br);
top =abcFrompts(tl,tr);
lft =abcFrompts(tl,bl);
rht =abcFrompts(tr,br);

ptA=lineIntersection(abc,bot);
ptB=lineIntersection(abc,top);
ptC=lineIntersection(abc,lft);
ptD=lineIntersection(abc,rht);
pt = [ptA ptB ptC ptD];
mx = mean(pt);
[~,ix]=sort(abs(pt-mx));
x = real(pt(ix(1:2)));
y = imag(pt(ix(1:2)));
a=line(x,y,'parent',a,varargin{2:end});
end

function abc=abcFrompts(pta,ptb)
abc=[imag(pta-ptb) real(ptb-pta) imag(conj(pta)*ptb)];
abc = abc/sqrt(abc(1)^2+abc(2)^2);
end

function pt = lineIntersection(abc1,abc2)

A = [abc1(1:2);abc2(1:2)];
if(abs(det(A))<1e-5)
    pt=[];
    return;
end
b = -[abc1(3);abc2(3)];
pt=A^-1*b;
pt=pt(1)+1j*pt(2);
end