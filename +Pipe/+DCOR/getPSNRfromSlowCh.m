function psnr = getPSNRfromSlowCh(vslw16,prms)
N=2^8;
vslw = double(vslw16)/(2^16-1); %[mv];
s0 = @(s,a) s;
s1 = @(s,a) sqrt(s.^2+prms.gamma^2*a.^2);
u0 = @(s,a) -0.5*prms.gamma*a;
u1 = @(s,a) 0.5*prms.gamma*a;
meanFGD = @(s,u) s*sqrt(2/pi).*exp(-u.^2*0.5./s.^2)+u.*(1-2*phi(-u./s));
M1analytic = @(s,a) 0.5*meanFGD(s0(s,a),u0(s,a))+0.5*meanFGD(s1(s,a),u1(s,a));

vslwTbl = linspace(prctile(vslw,5),prctile(vslw,95),N);

a = arrayfun(@(x) mysolve(@(x) M1analytic(prms.noiseSigma,x),x,0,1e6,1e-6),vslwTbl);
psnrTbl = a*prms.gamma./sqrt(prms.noiseSigma^2+prms.gamma^2*a);
psnr = psnrTbl(minind(abs(bsxfun(@minus,double(vslw(:)),vslwTbl)),[],2));
end

function x = mysolve(f,y,x0,x1,eps)

while x1-x0 > eps
   
    x = 0.5*(x1+x0);
    fx = f(x);

    if fx<y,
       x0 = x;
    else
       x1 = x;
    end
        
end

end


function [varargout] = phi(x,varargin)
%NORMCDF Normal cumulative distribution function (cdf).
%   P = NORMCDF(X,MU,SIGMA) returns the cdf of the normal distribution with
%   mean MU and standard deviation SIGMA, evaluated at the values in X.
%   The size of P is the common size of X, MU and SIGMA.  A scalar input
%   functions as a constant matrix of the same size as the other inputs.
%
%   Default values for MU and SIGMA are 0 and 1, respectively.
%
%   [P,PLO,PUP] = NORMCDF(X,MU,SIGMA,PCOV,ALPHA) produces confidence bounds
%   for P when the input parameters MU and SIGMA are estimates.  PCOV is a
%   2-by-2 matrix containing the covariance matrix of the estimated parameters.
%   ALPHA has a default value of 0.05, and specifies 100*(1-ALPHA)% confidence
%   bounds.  PLO and PUP are arrays of the same size as P containing the lower
%   and upper confidence bounds.
%
%   [...] = NORMCDF(...,'upper') computes the upper tail probability of the 
%   normal distribution. This can be used to compute a right-tailed p-value. 
%   To compute a two-tailed p-value, use 2*NORMCDF(-ABS(X),MU,SIGMA).
%
%   See also ERF, ERFC, NORMFIT, NORMINV, NORMLIKE, NORMPDF, NORMRND, NORMSTAT.

%   References:
%      [1] Abramowitz, M. and Stegun, I.A. (1964) Handbook of Mathematical
%          Functions, Dover, New York, 1046pp., sections 7.1, 26.2.
%      [2] Evans, M., Hastings, N., and Peacock, B. (1993) Statistical
%          Distributions, 2nd ed., Wiley, 170pp.

%   Copyright 1993-2013 The MathWorks, Inc.


if nargin<1
    error(message('stats:normcdf:TooFewInputsX'));
end

if nargin>1 && strcmpi(varargin{end},'upper')
    % Compute upper tail and remove 'upper' flag
    uflag=true;
    varargin(end) = [];
elseif nargin>1 && ischar(varargin{end})&& ~strcmpi(varargin{end},'upper')
    error(message('stats:cdf:UpperTailProblem'));
else
    uflag=false;  
end

[varargout{1:max(1,nargout)}] = localnormcdf(uflag,x,varargin{:});

end
function [p,plo,pup] = localnormcdf(uflag,x,mu,sigma,pcov,alpha)

if nargin < 3
    mu = 0;
end
if nargin < 4
    sigma = 1;
end

% More checking if we need to compute confidence bounds.
if nargout>1
   if nargin<5
      error(message('stats:normcdf:TooFewInputsCovariance'));
   end
   if ~isequal(size(pcov),[2 2])
      error(message('stats:normcdf:BadCovarianceSize'));
   end
   if nargin<6
      alpha = 0.05;
   elseif ~isnumeric(alpha) || numel(alpha)~=1 || alpha<=0 || alpha>=1
      error(message('stats:normcdf:BadAlpha'));
   end
end

try
    z = (x-mu) ./ sigma;
    if uflag==true
        z = -z;
    end
catch
    error(message('stats:normcdf:InputSizeMismatch'));
end

% Prepare output
p = NaN(size(z),class(z));
if nargout>=2
    plo = NaN(size(z),class(z));
    pup = NaN(size(z),class(z));
end

% Set edge case sigma=0
if uflag==true
    p(sigma==0 & x<mu) = 1;
    p(sigma==0 & x>=mu) = 0;
    if nargout>=2
        plo(sigma==0 & x<mu) = 1;
        plo(sigma==0 & x>=mu) = 0;
        pup(sigma==0 & x<mu) = 1;
        pup(sigma==0 & x>=mu) = 0;
    end
else
    p(sigma==0 & x<mu) = 0;
    p(sigma==0 & x>=mu) = 1;
    if nargout>=2
        plo(sigma==0 & x<mu) = 0;
        plo(sigma==0 & x>=mu) = 1;
        pup(sigma==0 & x<mu) = 0;
        pup(sigma==0 & x>=mu) = 1;
    end
end

% Normal cases
if isscalar(sigma)
    if sigma>0
        todo = true(size(z));
    else
        return;
    end
else
    todo = sigma>0;
end
z = z(todo);

% Use the complementary error function, rather than .5*(1+erf(z/sqrt(2))),
% to produce accurate near-zero results for large negative x.
p(todo) = 0.5 * erfc(-z ./ sqrt(2));

% Compute confidence bounds if requested.
if nargout>=2
   zvar = (pcov(1,1) + 2*pcov(1,2)*z + pcov(2,2)*z.^2) ./ (sigma.^2);
   if any(zvar<0)
      error(message('stats:normcdf:BadCovarianceSymPos'));
   end
   normz = -norminv(alpha/2);
   halfwidth = normz * sqrt(zvar);
   zlo = z - halfwidth;
   zup = z + halfwidth;

   plo(todo) = 0.5 * erfc(-zlo./sqrt(2));
   pup(todo) = 0.5 * erfc(-zup./sqrt(2));
end
end