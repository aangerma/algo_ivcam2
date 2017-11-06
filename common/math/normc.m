function n = normc(m)
%NORMC Normalize columns of a matrix.
%
%	Syntax
%
%	  normc(M)
%
%	Description
%
%	  NORMC(M) normalizes the columns of M to a length of 1.
%
%	Examples
%	  
%	  m = [1 2; 3 4]
%	  n = normc(m)
%
%	See also NORMR

% Mark Beale, 1-31-92
% Copyright 1992-2001 The MathWorks, Inc.
% $Revision: 1.8 $  $Date: 2001/01/08 18:30:54 $

if nargin < 1,error('Not enough input arguments.'); end

[mr,mc] = size(m);
if (mr == 1)
  n = ones(1,mc);
else
  n =ones(mr,1)*sqrt(ones./sum(m.*m)).*m;
end
