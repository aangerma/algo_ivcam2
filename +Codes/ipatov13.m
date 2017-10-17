function [tx,ker,c]=ipatov13(N)

c = [1  -2 -2  1  -2   1 1 1 1 1  -2  1  1];

ker = Utils.manchesterEncode(c,N);

tx = double(ker>0);

end