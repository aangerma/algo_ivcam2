function [xBo,eB] = gradientDecent(varargin)
%{
usage:
[xbest minE] = gradientDecent(x0,errFunc,
'xstep',xstep,
'maxIter',maxIter,
'eStepTol',eStepTol,
'xStepTol',xStepTol,
'verbose',true
)

o1 = rand(3,1);
o2 = randn(3,1);
hiddenFunc = @(x) sum((x-o1).^2);
xBest=gradientDecent(@(x) hiddenFunc(x),o2,'plot',true);
%}
% UNIQUE_KEY = (randi(2^31-1));
LINE_SEARCH_MAX_N=50;
p = parseInput(varargin{:});

if(p.verbose)
fprintff = @(varargin) fprintf(varargin{:});
else
    fprintff = @(varargin){};
end

errFunc = @(x) p.errFunc(p.denorm(x));



dim=length(p.x0);
xB=p.norm(p.x0);
dirGradMat=eye(dim)*p.xeps(:);
cnt = 0;
xGradStep=p.xstep;
% xeAcc = zeros(dim+1,0);
eB=inf;
xP=[];eP=[];
if(p.plot)
    indx = sum(double(mfilename));
%     while(ishandle(findobj(0,'number',indx)))
%          indx=indx+1;
%     end
    figure(indx);
end
while(true)
    fprintff('%4d ',cnt);
    eB_ = errFunc(xB);
    eGradStep = abs(eB_-eB);
    eB=eB_;
    
    
    if(p.plot)
       
        xBdn = p.denorm(xB);
        xBp = iff(min(dim,3),[xBdn;0;0],[xBdn;0],xBdn(1:min(dim,3)));
        xP(:,end+1)=xBp;%#ok
        eP(end+1)=eB;%#ok
        plot3(xP(1,:),xP(2,:),xP(3,:),xP(1,end),xP(2,end),xP(3,end),'ro');
        arrayfun(@(i) text(xP(1,i),xP(2,i),xP(3,i),sprintf('%f',eP(i))),1:size(xP,2));
        axis square
        axis vis3d
        grid on
        drawnow;
    end
    
    
    if(eGradStep<p.eStepTol)
        fprintff('END - reached min error step tolerance(eStepTol>%f)\n',eGradStep);
        break;
     end
    if(eB<p.eAbsTol)
        fprintff('END - reached absolute err threshold(eAbsTol>%f)\n',eB);
        break;
    end
    %calc derivative
    dx=zeros(dim,1);
    for i=1:dim
        xLi = xB+dirGradMat(:,i);
        dx(i)=errFunc(xLi)-eB;
        fprintff('.');
    end
    dx(isinf(dx))=0;    
    dx=dx/norm(dx)*xGradStep;
    

    %3 point parabolic fit
   
    eL(1)=eB;
    S=1;
    eL(2)=errFunc(xB-0.5*S*dx);
    eL(3)=errFunc(xB-S*dx);
    for i=1:LINE_SEARCH_MAX_N
    if(eL(2)<eL(1))
        break;
    end
        eL(3)=eL(2);
        S=S/2;
        eL(2)=errFunc(xB+0.5*S*dx);
    end
    th=[0 .25 1;0 .5 1;1 1 1]'\eL(:);
    L = -0.5*th(2)/th(1);
    L = min(max(L,0),1);
    xB_ = min(1,max(-1,xB-L*dx));
     p.xstep = norm(xB-xB_);
    xB=xB_;

  
    
    fprintff(' e = % 7f x = [',eB);
    fprintff('% 7f ',p.denorm(xB));
    fprintff('\b]\n');
    
    cnt = cnt+1;
  
    
   

   

     
    
    if(xGradStep<p.xStepTol)
        fprintff('END - reached min x variation(xStepTol>%f)\n',xGradStep);
        break;
    end
    
    if(cnt==p.maxIter)
        fprintff('END - reached maxIter(maxIter==%d)\n',cnt);
        break;
    end
end


 xBo=p.denorm(xB);

end

function [v,dv,d2f]=evalD(f,x0,xeps)
s = num2cell([-xeps 0 xeps] + x0(:),2);
x = cell(1,numel(s));
[x{:}]=ndgrid(s{:});
x=cellfun(@(x) x(:),x,'uni',0);
x=[x{:}];


res = arrayfun(@(i) f(x(i,:)),1:size(x,1));
H=[x.*x 2*x(:,1).*x(:,2) 2*x(:,1).*x(:,3) 2*x(:,2).*x(:,3) x];
th=pinv(H'*H)*H'*res(:);
% e =abs( H*th-res(:));
S = reshape(th([1 4 5 4 2 6 5 6 3]),[3 3]);
m = th(10:12);
% f_=sum((x*S).*x,2)+x*m;
% f_=reshape(v,size(res));
dv=(-S^-1*m);
d2v = S;
end


function p =parseInput(errFunc,x0,varargin)
p = inputParser;
dim = numel(x0);

addOptional(p,'xstep',1e-3);
addOptional(p,'xeps',1e-4);
addOptional(p,'xL',-ones(dim,1));
addOptional(p,'xH', ones(dim,1));
addOptional(p,'verbose',false,@(x) islogical(x));
addOptional(p,'plot',false,@(x) islogical(x));
addOptional(p,'maxIter',5000);
addOptional(p,'eStepTol',1e-5);
addOptional(p,'eAbsTol',1e-6);
addOptional(p,'xStepTol',1e-6);
parse(p,varargin{:});
p = p.Results;
p.x0=x0(:);
p.errFunc = errFunc;

p.xL=p.xL(:);
p.xH=p.xH(:);
p.norm = @(x) (x-p.xL)./(p.xH-p.xL);
p.denorm = @(x) (x).*(p.xH-p.xL)+p.xL;

end


function [x,f] = newton(func, x, step0, maxiter, mingrad, minstep, varargin)

sigma = 0.3;
beta = 0.5;
maxarmijoiter = 30;

if ~exist('minstep','var'), minstep = 0; end

% Fix (R,t) and solve for optimal alignment with the planes
for iter = 1:maxiter,
    
    %Negative gradient direction
    [f,df,d2f] = func(x, varargin{:});
    normg = norm(df);
    
    [U,D] = eig(d2f); 
    D = diag(D);
    mineig = min(D); 
    condition = max(abs(D))/min(abs(D));
    if  mineig < 1e-8,
        D = max(abs(D),1e-6);
        Hinv = U*diag(1./D)*inv(U);
        d = -Hinv*df;
    else
        d = -d2f\df;
    end

    if normg < mingrad, 
        fprintf(1, 'iter = %4d \t f=%.8g \t |g| = %.6g \t min. eig. = %8.6g \t cond = %8.6g\n', iter, f, normg, mineig, condition);
        return; 
    end    
    
    % Armijo rule
    step = step0;
    for k=1:maxarmijoiter
        xnew = x + step*d;
        fnew = func(xnew, varargin{:});
        if fnew - f < sigma*step*df'*d, break; end
        step = step*beta;
    end
    x = xnew;
    
    fprintf(1, 'iter = %4d \t f=%.8g \t |g| = %.6g \t min. eig. = %8.6g \t cond = %8.6g \t step=%.6g \t armijo=%4d \n', iter, f, normg, mineig, condition, step, k);
    
    if step < minstep, return; end
end
end