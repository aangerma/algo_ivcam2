function b=uint322bin(u,l)
b = vec(fliplr(dec2bin(u,32))')=='1';
b = b(1:l);
end