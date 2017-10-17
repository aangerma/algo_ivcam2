function ker = manchesterEncode(c,N)
if(N==0)
    ker = c;
    return;
end
c = c(:)';
ker = [c;-ones(N-1,length(c));-c];
ker = ker(:)';
end