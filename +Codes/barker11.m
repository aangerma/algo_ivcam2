function [tx,ker,c]=barker11
N=0;
c = [+1 +1 +1 -1 -1 -1 +1 -1 -1 +1 -1];
ker = [c;-ones(N,11);-c];
ker = ker(:);
tx = ker*.5+.5;
end
