function x = conv2noiman(I,c)
if(~all(mod(size(c),2)==1))
    error('Kernal size must be odd');
end
x = conv2(padarray(I,(size(c)-1)/2,'both','replicate'),c,'valid');
end