function [b,v]=sprivGetBaseVal(txt)
b=txt(1);
v=txt(2:end);
if(all(b~='bdshf'))
    error('Value first char should be b(inary) d(ecimal) s(igned) h(ex) f(loat) (%s)',txt);
end
if(~all(any(bsxfun(@eq,v,('1234567890.-+ABCDEFabcdef')'))))
    error('Value should contain numeric only (%s)',v);
end
end