function [h,dimpwr] = generateLSH(m,N)
%{
Given input of dim K=size(x,2), generate a matrix of all the
dimnesions in the power of N
returns:
h - h matrix
dimpwr - column power
matrix h is generated such that h(:,i)=m.^dimpwr(:,i), i=1...K


usage example:
[y,x,z]=ndgrid(linspace(-1,1,100));
x=x(:);y=y(:);z=z(:);
u = 0.2*x.^2 + 0.1*x.*y + 0.7*z.*x + randn(numel(x),1)*0.1;
%estimate the coficiants
[h,p]=generateLSH([x y z],2);
th=h\u;

p(:,1) equals to [2;0;0], which corresponds to x.^2, th(1) equals to 0.2
p(:,2) equals to [1;1;0], which corresponds to x.*y, th(2) equals to 0.1
p(:,3) equals to [1;0;1], which corresponds to x.*z, th(3) equals to 0.7

%}



dimpwr=arrayfun(@(i) allSum(size(m,2),i)',N:-1:0,'uni',0);
dimpwr=[dimpwr{:}];
h = arrayfun(@(i) prod(m.^(dimpwr(:,i)'),2),1:size(dimpwr,2),'uni',0);
h = [h{:}];
end


function m=allSum(k,N)
%creates a matrix m of all integer combinations such that sum(m,2)==N, size(m)=?,k
if(k==1)
    m=N;
elseif(N==0)
    m=zeros(1,k);
elseif(N==1)
    m=eye(k);
else
    m=zeros(0,k);
    for i=0:N
        m_=allSum(k-1,i);
        m = [m;[ones(size(m_,1),1)*(N-i) m_]]; %#ok<AGROW>
    end
end
end