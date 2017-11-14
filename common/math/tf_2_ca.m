function [d1,d2,beta]=tf_2_ca(b,a)
%TF2CA Transfer function to coupled allpass conversion.
%   [D1,D2] = TF2CA(B,A) where B is a real, symmetric vector of numerator
%   coefficients and A is a real vector of denominator coefficients, 
%   corresponding to a stable digital filter, returns real vectors D1 and
%   D2 containing the denominator coefficients of the allpass filters
%   H1(z) and H2(z) such that
%
%           B(z)   1
%   H(z) = ----- = - [H1(z) + H2(z)] (coupled allpass decomposition).
%           A(z)   2
%
%   [D1,D2] = TF2CA(B,A) where B is a real, antisymmetric vector of
%   numerator coefficients and A is a real vector of denominator
%   coefficients, corresponding to a stable digital filter, returns
%   real vectors D1 and D2 containing the denominator coefficients of
%   the allpass filters H1(z) and H2(z) such that
%
%           B(z)   1
%   H(z) = ----- = - [H1(z) - H2(z)].
%           A(z)   2
%
%   In some cases, the decomposition is not possible with real H1(z) and
%   H2(z), in those cases a generalized coupled allpass decomposition
%   may be possible, the syntax is:
%
%   [D1,D2,BETA] = TF2CA(B,A) returns complex vectors D1 and D2
%   containing the denominator coefficients of the allpass filters
%   H1(z) and H2(z), and a complex scalar BETA, satisfying |BETA| = 1,
%   such that
%
%           B(z)   1                                  (generalized
%   H(z) = ----- = - [conj(BETA)*H1(z) + BETA*H2(z)]  coupled allpass 
%           A(z)   2                                  decomposition).
%
%   In the above equations, H1(z) and H2(z) are (possibly complex) 
%   allpass IIR filters given by:
%
%           fliplr(conj(D1(z)))            fliplr(conj(D2(z)))
%   H1(z) = -------------------,   H2(z) = -------------------
%                 D1(z)                            D2(z)
%
%   where D1(z) and D2(z) are polynomials whose coefficients are given
%   by D1 and D2 respectively.
%
%   Note: A coupled allpass decomposition is not always possible. 
%         Nevertheless, Butterworth, Chebyshev, and Elliptic IIR 
%         filters, among others, can be factored in this manner.
%
%   EXAMPLE:
%      [b,a]=cheby1(9,.5,.4);
%      [d1,d2]=tf2ca(b,a); % TF2CA returns the denominators of the allpass
%      num = 0.5*conv(fliplr(d1),d2)+0.5*conv(fliplr(d2),d1);
%      den = conv(d1,d2); % Reconstruct numerator and denonimator
%      max([max(b-num),max(a-den)]) % Compare original and reconstructed
%
%   See also CA2TF, TF2CL, CL2TF, IIRPOWCOMP, TF2LATC, LATC2TF.

% References:[1] P.P. Vaidyanathan, ROBUST DIGITAL FILTER STRUCTURES, in
%               HANDBOOK FOR DIGITAL SIGNAL PROCESSING. S.K. Mitra and J.F.            
%               Kaiser Eds. Wiley-Interscience, N.Y., 1993, Chapter 7.
%            [2] P.P. Vaidyanathan, MULTIRATE SYSTEMS AND FILTER BANKS, 
%               Prentice Hall, N.Y., Englewood Cliffs, NJ, 1993, Chapter 3.

%   Author(s): R. Losada
%   Copyright 1999-2011 The MathWorks, Inc.

narginchk(2,2);

[b,a] = parseinput(b,a);

% Compute the power complementary filter
try
    [bp,a] = iirpowcomp(b,a);
catch ME
    throw(ME);
end

% Sort numerators to call allpassdecomposition
[p,q] = sortnums(b,bp);

% Once you have sorted the numerators, compute the actual decomposition
[d1,d2,beta] = allpassdecomposition(p,q,a);
end


%------------------------------------------------------------------------
function [b,a] = parseinput(b,a)
%PARSEINPUT Make sure input args are real vectors. 
%   
%   Force them to be row vectors

% Check that b and a are vectors of the same length
if ~(any(size(b)==1) && any(size(a)==1)),
   error(message('dsp:tf2ca:FilterErr1'));
   return
end
if length(b)~=length(a),
   error(message('dsp:tf2ca:FilterErr2'));
   return
end

% Make sure b and a are rows
b = b(:).';
a = a(:).';

if ~(isreal(b) && isreal(a)),
    error(message('dsp:tf2ca:FilterErr3'));
    return
end

% Make sure numerator is symmetric or antisymmetric
if(  sum( b(1,floor(end/2)) ~= flipud(b(ceil(end/2),end)) ) > 0 )
    error(message('dsp:tf2ca:FilterErr4'));
    return
end
end

%------------------------------------------------------------------------
function [p,q] = sortnums(b,bp)
%SORTNUMS Sort numerators prior to calling ALLPASSDECOMPOSITION.
%   ALLPASSDECOMPOSITION always requires the first argument to
%   be symmetric.  The second argument, can be
%   symmetric, or antisymmetric.
%
%   IIRPOWCOMP can be called in some cases with antisymmetric numerator
%   and return a symmetric power complementary numerator. In this
%   case, we must sort these arguments before proceeding

% If b is real, antisymmetric, make it the second arg
if max(abs(b + b(end:-1:1))) < eps^(2/3),
    p = bp;
    q = b;    
else
    p = b;
    q = bp;
end
end

%------------------------------------------------------------------------
function [d1,d2,beta] = allpassdecomposition(p,q,a)
%ALLPASSDECOMPOSITION  Compute the allpass decomposition.
%   Given an IIR filter P/A and its power complementary filter Q/A
%   find the allpass decomposition for the filter:
%
%           P(z)   1                                  (generalized
%   H(z) = ----- = - [conj(BETA)*H1(z) + BETA*H2(z)]  coupled allpass 
%           A(z)   2                                  decomposition).
%
%   NOTE: In this function, if P is real it must always be symmetric.
%         Make sure you sort the args correctly prior to calling this 
%         function.


% If q is real, antisymmetric, make it imaginary
if isreal(q) && (max(abs(q + q(end:-1:1))) < eps^(2/3)),
    q = q*i;
end

z = roots(p-i*q);
   
% Initialize the allpass functions
d1 = 1;
d2 = 1;

% Separate the zeros inside the unit circle and the ones outside to form the allpass functions
for n=1:length(z),
   if abs(z(n)) < 1,
      d2 = conv(d2,[1 -z(n)]);
   else
      d1 = conv(d1,[1 -1/conj(z(n))]);
   end
end

% Remove roundoff imaginary parts
d1 = signalpolyutils('imagprune',d1);
d2 = signalpolyutils('imagprune',d2);

beta = sum(d2)*(sum(p)+i*sum(q))./sum(a)./sum(conj(d2));
end


%------------------------------------------------------------------------
function [q,a] = iirpowcomp(b,a,varargin)
%IIRPOWCOMP   IIR power complementary filter.
%   [Bp,Ap] = IIRPOWCOMP(B,A) returns the coefficients of the power
%   complementary IIR filter G(z) = Bp(z)/Ap(z) in vectors Bp and Ap,
%   given the coefficients of the IIR filter H(z) = B(z)/A(z) in
%   vectors B and A.  B must be symmetric (hermitian) or antisymmetric
%   (antihermitian) and of the same length as A.
%
%   The two power complementary filters satisfy the relation
%                     2          2
%               |H(w)|  +  |G(w)|   =   1.
%
%   [Bp,Ap,C] = IIRPOWCOMP(B,A) where C is a complex scalar of magnitude
%   one, forces Bp to satisfy the generalized hermitian property
%
%                         conj(Bp(end:-1:1)) = C*Bp.
%
%   When C is omitted, it is chosen as follows:
%   
%     - If B is real, C is chosen as 1 or -1, whichever yields Bp real.
%     - If B is complex, C always defaults to 1.
%
%   Ap is always equal to A.
%
%   EXAMPLE:
%      [b,a] = cheby1(4,.5,.4);
%      [bp,ap]=iirpowcomp(b,a);
%      fvtool(b,a,bp,ap,'MagnitudeDisplay','Magnitude squared');
%
%   See also TF2CA, TF2CL, CA2TF, CL2TF.

%   Author(s): R. Losada
%   Copyright 1999-2011 The MathWorks, Inc.

narginchk(2,3);

% Make sure b and a are valid, return them as rows and also
% return the filter order
[b,a,N] = inputparse(b,a);

% Find the auxiliary polynomial R(z)
r = auxpoly(b,a);

% compute the numerator of the power complementary transfer function
[q] = powercompnum(b,r,N,varargin{:});
end

%------------------------------------------------------------------------
function [b,a,N] = inputparse(b,a)
%INPUTPARSE   Parse input arguments, and return filter order
%   INPUTPARSE  checks if b and a are valid numerator and
%   denominator vectors, converts them to rows if necessary
%   and returns the filter order N.

N = length(b)-1; % Get the order of the numerator

% Check that b and a are vectors of the same length
if ~any(size(b)==1) || ~any(size(a)==1),
   error(message('dsp:iirpowcomp:FilterErr1'));
   return;
end
if length(b)~=length(a),
   error(message('dsp:iirpowcomp:FilterErr2'));
   return;
end

% Make sure b and a are rows
b = b(:).';
a = a(:).';

% Check that b is hermitian or antihermitian.
% Symmetric and antisymmetric are special cases

if N < 1,
    error(message('dsp:iirpowcomp:FilterErr3'));
    return;
end
end
%------------------------------------------------------------------------
function r = auxpoly(b,a)
%AUXPOLY  Compute auxiliary polynomial necessary for the computation
%         of the power complementary filter's numerator.

% Find the reversed conjugated polynomial of b and a by replacing z with z^(-1) and
% conjugating the coefficients
revb = conj(b(end:-1:1));
reva = conj(a(end:-1:1));


% R(z) = z^(-N)*[conj(fliplr(b(z)))*b(z)-conj(fliplr(a(z)))*a(z)]
r = conv(revb,b) - conv(a,reva);
end
%------------------------------------------------------------------------
function [q] = powercompnum(b,r,N,varargin)
%POWERCOMPNUM  Compute numerator of power complementary filter.


if isreal(b) && (nargin == 3),
    % Try to get a real q with c = 1 and c = -1
    q = numrecursion(r,N,1); 
    
    if ~isreal(q),
        q = numrecursion(r,N,-1); 
    end
    
    if ~isreal(q),
        error(message('dsp:iirpowcomp:FilterErr4'));
        return
    end
else
    % If numerator is complex, we use c=1 when c is not given
    c = 1;
    if nargin == 4,
        c = varargin{1};
        if max(size(c)) > 1,
            error(message('dsp:iirpowcomp:FilterErr5'));
            return
        end
        if abs(c) - 1 > eps^(2/3),
            error(message('dsp:iirpowcomp:FilterErr6'));
            return
        end
    end
    
    [q] = numrecursion(r,N,c); 
end
end

%------------------------------------------------------------------------
function [q] = numrecursion(r,N,c)
%NUMRECURSION, compute the numerator of the power complementary function.
%   NUMRECURSION recursively computes the numerator q of the power
%   complementary transfer function needed to compute the allpass
%   decomposition.
%   Inputs:
%    r - auxiliary polynomial used in the recursion (defined above).
%    N - order of the IIR filter.
%
%   Output:
%    q - numerator of the power complemetary transfer function.

 
% Initialize recursion
q(1) = sqrt(-r(1)./c); q(N+1)=conj(c*q(1));
q(2) = -r(2)./(2*c*q(1)); q(N)=conj(c*q(2));

% The limit of the for loop depends on the order being odd or even
for n = 3:ceil(N/2),
   q(n) = (-r(n)./c - q(2:n-1)*q(n-1:-1:2).')./(2*q(1));
   q(N+2-n) = conj(c*q(n));
end

% Compute middle coefficient separately when order is even
if rem(N,2) == 0,
   q((N+2)/2) = (-r((N+2)/2)./c - q(2:(N+2)/2-1)*q((N+2)/2-1:-1:2).')./(2*q(1));
end

% [EOF] - IIRPOWCOMP.M
end

function varargout = signalpolyutils(varargin)
%SIGNALPOLYUTILS   utility functions for vectors of polynomial coefficients.
%   S = SIGNALPOLYUTILS provides access to a number of local functions that
%   have a variety of polynomial manipulation and testing utilities.

%   Author(s): R. Losada
%   Copyright 1988-2012 The MathWorks, Inc.

[varargout{1:max(1,nargout)}] = feval(varargin{:});
end

%----------------------------------------------------------------------------
function polynom = imagprune(polynom,tol) %#ok
%IMAGPRUNE  Remove imaginary part when smaller than tol.

if nargin<2, tol=[]; end
if isempty(tol), tol = eps^(2/3); end
 
if max(abs(imag(polynom))) < tol,
   polynom = real(polynom);
end
end

%-----------------------------------------------------------------------------
function symstr = symmetrytest(b,removezerosFlag,tol)
%SYMMETRYTEST  Test if vector corresponds to a symmetric or antisymmetric polynomial.

if nargin<2, removezerosFlag=[]; end
if isempty(removezerosFlag), removezerosFlag = 0; end

if nargin<3, tol=[]; end
if isempty(tol), tol = eps^(2/3); end

% Make sure b is a row
b = b(:).';

if removezerosFlag,
    % Remove leading and trailing zeros of b 
    b = removezeros(b);
end

% Try complex first
switch isreal(b)
case 0,
    if max(abs(b - conj(b(end:-1:1)))) <= tol,
        symstr = 'hermitian';
    elseif max(abs(b + conj(b(end:-1:1)))) <= tol,
        symstr = 'antihermitian';
    else
        symstr = 'none';
    end
    
case 1,
    if max(abs(b - b(end:-1:1))) <= tol,
        symstr = 'symmetric';
    elseif max(abs(b + b(end:-1:1))) <= tol,
        symstr = 'antisymmetric';
    else
        symstr = 'none';
    end    
end
end

%------------------------------------------------------------------------------------
function filtertype = determinetype(h,issymflag,removezerosFlag) %#ok
%DETERMINETYPE  Determine the type of the filter based on 
%               the length and the symmetry of the filter.

if removezerosFlag,
    % Remove leading and trailing zeros of b 
    h = removezeros(h);
end
N = length(h) - 1;

if issymflag,
    % Type 1 or type 2
    if rem(N,2),
        % Odd order
        filtertype = 2;
    else
        % Even order
        filtertype = 1;
    end
else
    % Type 3 or type 4
    if rem(N,2),
        % Odd order
        filtertype = 4;
    else
        % Even order
        filtertype = 3;
    end
end
end

%-----------------------------------------------------------------------------
function flag = isminphase(b,tol)
%ISMINPHASE  Test to see if polynomial has all its roots on or inside the unit circle.

if nargin<2, tol=[]; end
if isempty(tol), tol = eps^(2/3); end

flag = 1;

% First test if polynomial is strictly minimum-phase, i.e. all its roots are
% strictly inside the unit circle.
stableflag = isstable(b);
if stableflag,
    return
end

% If not strictly minimum-phase, it can still be minimum-phase, try this.

% Remove trailing zeros of b before calling roots, otherwise, the order of
% the input polynomial will be incorrect. 
if ~isempty(b)
  b1 = b(1:find(b~=0, 1, 'last'));
else
  b1 = b;
end

z = roots(b1);
if ~isempty(z) && (max(abs(z)) > 1 + tol),
    flag = 0;        
end
end

%------------------------------------------------------------------------------
function flag = isstable(a)
%ISSTABLE  Test to see if polynomial has all its roots inside the unit circle.

% Remove trailing zeros
a = a(1:find(a~=0, 1, 'last' ));

% Remove leading zeros as they have no effect on stability but affect the
% normalization
indx = find(a, 1);
if ~isempty(indx),
    a = a(indx:end);
else
    % All zeros
    error(message('signal:signalpolyutils:SignalErr'));
end

a = a./a(1);    % Normalize by a(1)

if length(a) == 1,
    flag = 1;
    
elseif length(a) == 2,
    
    % One pole given by second coefficient of a, first is always 1.
    flag = isfirstorderstable(a(2));

else
    % Use poly2rc for denominators of order 2 or more
    flag = ispolystable(a);
        
end
end

%----------------------------------------------------------------------------
function isstableflag = isfirstorderstable(p)
% One pole given by second coefficient of a, first is always 1.
if abs(p) < 1,        
    isstableflag = 1;
else
    isstableflag = 0;
end
end

%----------------------------------------------------------------------------
function isstableflag = ispolystable(a)

% look at the last coefficient, if greater or equal to 1, unstable
if abs(a(end)) >= 1,
    isstableflag = 0;
    return
end

% Use poly2rc to determine stability
try
    k = poly2rc(a); % This can throw a divide by zero warning
    if any(isnan(k)) || max(abs(k)) >= 1,
        isstableflag = 0;
    else
        isstableflag = 1;
    end
catch %#ok<CTCH>
    % If poly2rc fails, one of the k's must be equal to one, unstable
    isstableflag = 0;
end
end


%----------------------------------------------------------------------------
function isfirflag = isfir(b,a)
%ISFIR(B,A) True if FIR.
if nargin<2, a=[]; end
if isempty(a), a=1; end
if ~isvector(b) || ~isvector(a)
  error(message('signal:signalpolyutils:InvalidDimensions'));
end

if find(a ~= 0, 1, 'last') > 1,
  isfirflag = 0;
else
  isfirflag = 1;
end
end

%----------------------------------------------------------------------------
function islinphaseflag = islinphase(b,a,tol) %#ok
%ISLINPHASE(B,A) True if linear phase
if nargin<3, tol=[]; end
if isempty(tol), tol=eps^(2/3); end
if isfir(b,a),
  islinphaseflag = determineiflinphase(b,tol);
else
  if isstable(a),
    % Causal stable IIR filters cannot have linear phase
    islinphaseflag = 0;
  else
    islinphaseflag = (determineiflinphase(b,tol) & determineiflinphase(a,tol));
  end
end        
end

%----------------------------------------------------------------------------
function islinphaseflag = determineiflinphase(b,tol)
if nargin<2, tol=[]; end
if isempty(tol), tol=eps^(2/3); end

% Set defaults
islinphaseflag = 0;

% If b is a scalar, filter is always FIR and linear-phase
if length(b) == 1,
    islinphaseflag = 1;
    return
end

symstr = symmetrytest(b,1,tol);

if ~strcmpi(symstr,'none'),
    islinphaseflag = 1;
end
end

%----------------------------------------------------------------------------
function ismaxphaseflag = ismaxphase(b,a,tol) %#ok
%ISMAXPHASE(B,A) True if maximum phase
% Initialize flag to true.
if nargin<3, tol=[]; end
if isempty(tol), tol = eps^(2/3); end
ismaxphaseflag = 1;

% Remove trailing zeros of b before calling roots, otherwise, the order of
% the input polynomial will be incorrect. 
if ~isempty(b)
  b1 = b(1:find(b~=0, 1, 'last'));
else
  b1 = b;
end

% If there is a zero at the origin, filter is not max phase
if any(roots(b1)==0) || length(a) > length(b) || ...
     ~isminphase(conj(b(end:-1:1)),tol) || ...
     ~isstable(a);
  ismaxphaseflag = 0;
end
end

%----------------------------------------------------------------------------
function isallpassflag = isallpass(b,a,tol) %#ok
%ISALLPASS(B,A,TOL) returns true if allpass.
% If the numerator and denominator are conjugate reverses of each other,
% then the filter is allpass. 

%isallpass(b,a,tol)  True if allpass.
if nargin<3, tol=[]; end
if isempty(tol), tol = eps^(2/3); end

% Get out if empty so no indexing errors occur.
if isempty(a) && isempty(b)
  isallpassflag = 1;
  return
end

% Remove trailing zeros.
b = removetrailzeros(b);
a = removetrailzeros(a);

% Remove leading zeros.
b = b(find(b, 1):end);
a = a(find(a, 1):end);

% Get out if one of them is now empty so no indexing errors occur.
if isempty(a) || isempty(b)
  isallpassflag = 0;
  return
end

% Get out of one is zero so no divide-by-zero warnings occur.
if a(1)==0 || b(end)==0
  isallpassflag = 0;
  return
end

% Normalize
a = a./a(1);
b = b./b(end);

% If the numerator and denominator are conjugate reverses of each other,
% then the filter is allpass. 
if length(b)==length(a) && max(abs(conj(b(end:-1:1)) - a)) < tol,
  isallpassflag = 1;
else
  isallpassflag = 0;
end
end

%----------------------------------------------------------------------------
function t = isvector(v)
%ISVECTOR  True for a vector.
%   ISVECTOR(V) returns 1 if V is a vector and 0 otherwise.
t = ismatrix(v) & min(size(v))<=1;
end

%----------------------------------------------------------------------------
function b = removezeros(b)
%REMOVEZEROS  Remove leading and trailing zeros of b

if max(abs(b)) == 0,
    b = 0;
else
    % Remove leading and trailing zeros of b 
    b = b(find(b,1):find(b,1, 'last'));
end
end

