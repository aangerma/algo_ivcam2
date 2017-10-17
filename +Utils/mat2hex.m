function matout=mat2hex(matin,n)
%matin - N x K input N entries, each of size K values
%matout - N x K*n output N entries, with K values, each represented with n nibbles
matout=fliplr(dec2hexFast(matin',n))';
matout = vec(matout)';
matout = reshape(matout,size(matin,2)*n,[])';
matout=fliplr(matout);
end