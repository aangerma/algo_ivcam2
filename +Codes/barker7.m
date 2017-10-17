function [tx,ker,c]=barker7(N)
if(~exist('N','var'))
    N=0;
end
c = [+1 +1 +1 -1 -1 +1 -1];
ker = [c;-ones(N,7);-c];
ker = ker(:)';
tx = ker*.5+.5;
end
