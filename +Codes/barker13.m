function [tx,ker,c]=barker13()

c = [1 1 1 1 1 -1 -1 +1 +1 -1 +1 -1 +1]';

ker = Utils.manchesterEncode(c,1)';

tx = double(ker>0);
end
