function v=sprivRegstruct2uint32val(s)
v=zeros(length(s),1,'uint32');
dvals = find([s.base]=='d');
for i=dvals
    v(i) = dec2hex(uint32(str2double(s(i).value)));
end
bvals = find([s.base]=='b');
for i=bvals
    v(i) = uint32(bin2dec(s(i).value));
end
fvals = find([s.base]=='f');
for i=fvals
    v(i) = typecast(single(str2double(s(i).value)),'uint32');
end
end