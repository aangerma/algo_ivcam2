function [xB,eB] = gradientDecent(varargin)
%{
usage:
[xbest minE] = gradientDecent(x0,errFunc,
'xStep',xstep,
'maxIter',maxIter,
'eTol',eTol,
'xTol',xTol,
'verbose',true
)

o1 = rand(2,1);
o2 = randn(2,1);
hiddenFunc = @(x) sum((x-o1).^2);
xBest=gradientDecent(rand(2,1),@(x) hiddenFunc(x),1);
%}
% UNIQUE_KEY = (randi(2^31-1));
p = parseInput(varargin{:});

fprintff = @(varargin) iff(p.verbose,fprintf(varargin{:}),'');

dim=length(p.x0);
xB=p.x0;
fprintff('calc e0 ');
eB = p.errFunc(xB);
fprintff('done(eB=%f)\n',eB);
x_lasso=p.xStep;
dirGradMat=eye(dim)*p.xEps;
cnt = 0;

% xeAcc = zeros(dim+1,0);

while(true)
    fprintff('%4d dx',cnt);
    %calc derivative
    ei=zeros(dim,1);
    for i=1:dim
        xLi = xB+dirGradMat(:,i);
        ei(i)=p.errFunc(xLi);
        fprintff('.');
    end
    dx = ei-eB;
    dx(isinf(ei))=0;    
    dx=dx/norm(dx)*p.xStep;
    %LINE SEARCH BACKTRACKING
    eL = inf;
    aL = 2;
    fprintff(' bt');
    while(eL>eB)
        aL = aL/2;
        xL = xB-aL*dx;
        eL=p.errFunc(xL);
        fprintff('^');
    end
%     x_lasso=aL*2;
    %update lasso distance
    
    
    
    %Line SEARCH LOCAL MINIMUM
    fprintff(' min');
    alpha = 0.9;
    while(true)
      
        xM = xL*alpha+xB*(1-alpha);
        
        eM=p.errFunc(xM);
        if(eL>eM)
            eL = eM;
            xL = xM;
        else
            break;
        end
        fprintff('v');
    end
    xGradStep = norm(xL-xB);
    eGradStep = abs(eL-eB);
    xB = xL;
    eB = eL;
    fprintff(' e = %f x = %s\n',eL,mat2str(xB));
    
    
    cnt = cnt+1;
    
%     
%     if(p.plot)
%         f = figure(UNIQUE_KEY);
%         ah = axes('parent',f);
%         switch(dim)
%             case 1
%                 plot(xeAcc(1,:),xeAcc(2,:),'.','parent',ah);
%                 xlabel('X');ylabel('Error');
%             otherwise
%                 plot3(xeAcc(1,:),xeAcc(2,:),xeAcc(end,:),'.','parent',ah);
%                 xlabel('X(1)');ylabel('X(2)');zlabel('Error');
% 
%         end
%     end
    
    %STOP CRITERIA
    if(eGradStep<p.eTol)
        fprintff('reached max error variation(%f)\n',eGradStep);
        break;
    end
    if(xGradStep<p.xTol)
        fprintff('reached max x variation(%f)\n',xGradStep);
        break;
    end
    
    if(cnt>p.maxIter)
        fprintff('reached maxIter(%d)\n',cnt);
        break;
    end
end


 

end


function p =parseInput(x0,errFunc,varargin)
p = inputParser;
addOptional(p,'xEps',1e-6);
addOptional(p,'xStep',1);
addOptional(p,'verbose',false,@(x) islogical(x));
addOptional(p,'plot',false,@(x) islogical(x));
addOptional(p,'maxIter',100);
addOptional(p,'eTol',1e-5);
addOptional(p,'xTol',1e-5);
parse(p,varargin{:});
p = p.Results;
p.x0=x0;
p.errFunc = errFunc;


end