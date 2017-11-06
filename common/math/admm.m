function [x, z, k] = admm(b, D, M, lambda1, lambda2, rho, alpha, QUIET, MAX_ITER, ABSTOL, RELTOL, x)
%solve:
%x min_x { ||b-Mx||^2 + lambda|Dx|_1 }

t_start = tic;
 

% Defaults
if ~exist('alpha', 'var')    || isempty(alpha),      alpha    = 1;       end
if ~exist('QUIET', 'var')    || isempty(QUIET),      QUIET    = 1;       end
if ~exist('MAX_ITER', 'var') || isempty(MAX_ITER),   MAX_ITER = 1e4;     end
if ~exist('ABSTOL', 'var')   || isempty(ABSTOL),     ABSTOL   = 1e-4;    end
if ~exist('RELTOL', 'var')   || isempty(RELTOL),     RELTOL   = 1e-3;    end

if(~exist('x','var') || isempty(x)),x = zeros(size(D,2),size(b,2));end


z = D*x;

%z = zeros(size(D,1),1);
u = zeros(size(D,1),size(b,2));
n = size(x,1);
m = size(x,2);



if ~QUIET
    fprintf('%3s\t%10s\t%10s\t%10s\t%10s\t%10s%10s\n', 'iter', ...
        'r norm', 'eps pri', 's norm', 'eps dual', 'objective','cond %');
end

DtD = D'*D;
MtM = M'*M;

MtM = MtM + lambda2*eye(size(M,2));

Mtb = M'*b;
Q   = inv(MtM + rho*DtD);


% c = zeros(1,MAX_ITER);
% ep = zeros(1,MAX_ITER);
% ed = zeros(1,MAX_ITER);
% c = zeros(size(x,1),MAX_ITER);

cond =  zeros(1,m);


if(strcmpi(class(D),'gpuArray'))
    x = gpuArray(x);
    u = gpuArray(u);
    cond = gpuArray(cond);
end

ii = 1:m;

for k = 1:MAX_ITER
    
    
    zold = z(:,ii);
    uold = u(:,ii);
    
    % x-update
    x(:,ii) = Q * (Mtb(:,ii) + rho*D'*(zold-uold));%#ok
    
    
    % z-update with relaxation
    
    Dx = D*x(:,ii);
    Ax_hat = alpha*Dx + (1-alpha)*zold; %alpha*D*x +(1-alpha)*zold;
    znew = shrinkage(Ax_hat + uold, lambda1/rho);
    z(:,ii) = znew;
    
    % y-update
    unew = uold + Ax_hat - znew;
    u(:,ii) = unew;
    
    
    r_norm   = sqrt(sum((Dx - znew).^2, 1));
    s_norm   = sqrt(sum((-rho*D'*(znew - zold)).^2, 1));
    
    eps_pri  = sqrt(n)*ABSTOL + RELTOL*sqrt(max(sum((Dx).^2,1), sum(znew.^2,1)));
    eps_dual = sqrt(n)*ABSTOL + RELTOL*sqrt(sum((rho*D'*unew).^2,1));
    
    if ~QUIET
        % diagnostics, reporting, termination checks
        objval  = objective(b, M, lambda1, lambda2, x, z);
        
        fprintf('%3d\t%10.4f\t%10.4f\t%10.4f\t%10.4f\t%10.2f%10.2f\n', k, ...
            max(r_norm), max(eps_pri), ...
            max(s_norm), max(eps_dual), mean(objval),nnz(cond)/length(cond)*100);
    end
    
    
    cond(ii) = min(1,cond(ii) + double((r_norm < eps_pri).*(s_norm < eps_dual)));

    ii = find(cond==0);
    
   
    if all(cond)
        break;
    end
end
% if(nnz(z)==0)
%     z;
% end
if ~QUIET
    toc(t_start);
end


function obj = objective(b, M, lambda1, lambda2, x, z)
%obj = .5*norm(M*x - b)^2 + lambda1*norm(z,1) + .5*lambda2*norm(x)^2;
obj = .5*sum((M*x - b).^2,1) + lambda1*sum(abs(z),1) + .5*lambda2*sum(x.^2,1) ;


function y = shrinkage(a, kappa)
     y = max(0, a-kappa) - max(0, -a-kappa);
%    y = max(0, a-kappa);


  s = 0.357403*kappa;
%   y=a+kappa*(-exp(-0.5/s.^2*(a-kappa).^2)+exp(-0.5/s.^2*(a+kappa).^2));
