function [xB,eB] = gradientDecent(varargin)
%{
usage:
[xbest minE] = gradientDecent(x0,errFunc,
'xStep',xstep,
'maxIter',maxIter,
'eTol',eTol,
'xTol',xTol,
'plot',false,
'verbose',true
)

o1 = rand(12,1);
o2 = randn(12,1);
hiddenFunc = @(x) sum((x.*o2-o1).^2)+rand*0.2;
xBest=gradientDecent(rand(12,1),@(x) hiddenFunc(x),1);
%}
UNIQUE_KEY = (randi(2^31-1));
p = parseInput(varargin{:});

fprintff = @(varargin) iff(p.verbose,fprintf(varargin{:}),'');

dim=length(p.x0);
xB=p.x0;
fprintff('calc e0...');
eB = p.errFunc(xB);
fprintff('done\n');
x_lasso=p.xStep*100;
dirGradMat=eye(dim)*p.xStep;
cnt = 0;

xeAcc = zeros(dim+1,0);

while(true)
    fprintff('%4d dx',cnt);
    %calc derivative
    ei=zeros(dim,1);
    for i=1:dim
        xL = xB+dirGradMat(:,i);
        ei(i)=errFunc(xL);
        fprintff('.');
    end
    dx = eB-ei;
    dx(isinf(ei))=0;    
    dx=dx/norm(dx)*p.xStep;
    %LINE SEARCH BACKTRACKING
    eL = inf;
    aL = x_lasso*2;
    fprintff(' bt');
    while(eL>eB)
        aL = aL/2;
        xL = xB+aL*dx;
        eL=errFunc(xL);
        fprintff('.');
    end
    %update lasso distance
    x_lasso=aL;
    
    
    %Line SEARCH LOCAL MINIMUM
    fprintff(' min');
    while(true)
        aL = aL/2;
        xL = xB+aL*dx;
        eM=errFunc(xL);
        if(eL>eM)
            eL = eM;
        else
            break;
        end
        fprintff('.');
    end
    xGradStep = norm(xL-xB);
    eGradStep = eL-eB;
    xB = xL;
    eB = eL;
    fprintff(' e = %f x = %s\n',eL,mat2str(xB));
    
    
    cnt = cnt+1;
    
    
    if(p.plot)
        f = figure(UNIQUE_KEY);
        ah = axes('parent',f);
        switch(dim)
            case 1
                plot(xeAcc(1,:),xeAcc(2,:),'.','parent',ah);
                xlabel('X');ylabel('Error');
            otherwise
                plot3(xeAcc(1,:),xeAcc(2,:),xeAcc(end,:),'.','parent',ah);
                xlabel('X(1)');ylabel('X(2)');zlabel('Error');

        end
    end
    
    %STOP CRITERIA
    if(norm(eGradStep)<p.eTol)
        fprintff('reached max error variation(%f)\n',eGradStep);
        break;
    end
    if(xGradStep<p.xTol)
        fprintff('reached max x variation(%f)\n',xGradStep);
        break;
    end
    
    if(cnt>maxIter)
        fprintff('reached maxIter(%d)\n',cnt);
        break;
    end
end


    function e=errFunc(x)
        e = p.errFunc(x);
        xeAcc(:,end+1)=[vec(x);e];
    end

end


function p =parseInput(x0,errFunc,varargin)
p = inputParser;
addOptional(p,'xStep',1);
addOptional(p,'verbose',false,@(x) islogical(x));
addOptional(p,'plot',false,@(x) islogical(x));
addOptional(p,'maxIter',100);
addOptional(p,'eTol',1e-3);
addOptional(p,'xTol',1e-3);
parse(p,varargin{:});
p = p.Results;
p.x0=x0;
p.errFunc = errFunc;


end