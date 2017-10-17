function [tx,ker,c]=golay26()
s1= -1+2*[0 0 0 1 1 0 0 0 1 0 1 1 0 1 0 1 0 1 1 0 0 1 0 0 0 0];
s2= -1+2*[0 0 0 0 1 0 0 1 1 0 1 0 0 0 0 0 1 0 1 1 1 0 0 1 1 1];
c = [s1 s2];

ker = Utils.manchesterEncode(c,1);

tx = double(ker>0)';
end