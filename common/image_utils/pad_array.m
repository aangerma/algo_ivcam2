function b = pad_array(varargin)
%PADARRAY Pad array.
%   B = PADARRAY(A,PADSIZE) pads array A with PADSIZE(k) number of zeros
%   along the k-th dimension of A.  PADSIZE should be a vector of
%   nonnegative integers.
%
%   B = PADARRAY(A,PADSIZE,PADVAL) pads array A with PADVAL (a scalar)
%   instead of with zeros.
%
%   B = PADARRAY(A,PADSIZE,PADVAL,DIRECTION) pads A in the direction
%   specified by the string DIRECTION.  DIRECTION can be one of the
%   following strings.
%
%       String values for DIRECTION
%       'pre'         Pads before the first array element along each
%                     dimension .
%       'post'        Pads after the last array element along each
%                     dimension.
%       'both'        Pads before the first array element and after the
%                     last array element along each dimension.
%
%   By default, DIRECTION is 'both'.
%
%   B = PADARRAY(A,PADSIZE,METHOD,DIRECTION) pads array A using the
%   specified METHOD.  METHOD can be one of these strings:
%
%       String values for METHOD
%       'circular'    Pads with circular repetition of elements.
%       'replicate'   Repeats border elements of A.
%       'symmetric'   Pads array with mirror reflections of itself.
%
%   Class Support
%   -------------
%   When padding with a constant value, A can be numeric or logical.
%   When padding using the 'circular', 'replicate', or 'symmetric'
%   methods, A can be of any class.  B is of the same class as A.
%
%   Example
%   -------
%   Add three elements of padding to the beginning of a vector.  The
%   padding elements contain mirror copies of the array.
%
%       b = padarray([1 2 3 4],3,'symmetric','pre')
%
%   Add three elements of padding to the end of the first dimension of
%   the array and two elements of padding to the end of the second
%   dimension.  Use the value of the last array element as the padding
%   value.
%
%       B = padarray([1 2; 3 4],[3 2],'replicate','post')
%
%   Add three elements of padding to each dimension of a
%   three-dimensional array.  Each pad element contains the value 0.
%
%       A = [1 2; 3 4];
%       B = [5 6; 7 8];
%       C = cat(3,A,B)
%       D = padarray(C,[3 3],0,'both')
%
%   See also CIRCSHIFT, IMFILTER.

%   Copyright 1993-2014 The MathWorks, Inc.

[a, method, padSize, padVal, direction] = ParseInputs(varargin{:});

b = padarray_algo(a, padSize, method, padVal, direction);

%%%
%%% ParseInputs
%%%
function [a, method, padSize, padVal, direction] = ParseInputs(varargin)

narginchk(2,4);

% fixed syntax args
a         = varargin{1};
padSize   = varargin{2};

% default values
method    = 'constant';
padVal    = 0;
direction = 'both';

validateattributes(padSize, {'double'}, {'real' 'vector' 'nonnan' 'nonnegative' ...
    'integer'}, mfilename, 'PADSIZE', 2);

% Preprocess the padding size
if (numel(padSize) < ndims(a))
    padSize           = padSize(:);
    padSize(ndims(a)) = 0;
end

if nargin > 2
    
    firstStringToProcess = 3;
    
    if ~ischar(varargin{3})
        % Third input must be pad value.
        padVal = varargin{3};
        validateattributes(padVal, {'numeric' 'logical'}, {'scalar'}, ...
            mfilename, 'PADVAL', 3);
        
        firstStringToProcess = 4;
        
    end
    
    for k = firstStringToProcess:nargin
        validStrings = {'circular' 'replicate' 'symmetric' 'pre' ...
            'post' 'both'};
        string = validatestring(varargin{k}, validStrings, mfilename, ...
            'METHOD or DIRECTION', k);
        switch string
            case {'circular' 'replicate' 'symmetric'}
                method = string;
                
            case {'pre' 'post' 'both'}
                direction = string;
                
            otherwise
                error(message('images:padarray:unexpectedError'))
        end
    end
end

% Check the input array type
if strcmp(method,'constant') && ~(isnumeric(a) || islogical(a))
    error(message('images:padarray:badTypeForConstantPadding'))
end

function b = padarray_algo(a, padSize, method, padVal, direction)
%PADARRAY_ALGO Pad array.
%   B = PADARRAY_AGLO(A,PADSIZE,METHOD,PADVAL,DIRECTION) internal helper
%   function for PADARRAY, which performs no input validation.  See the
%   help for PADARRAY for the description of input arguments, class
%   support, and examples.

%   Copyright 2014 The MathWorks, Inc.

if isempty(a)
    
    numDims = numel(padSize);
    sizeB = zeros(1,numDims);
    
    for k = 1: numDims
        % treat empty matrix similar for any method
        if strcmp(direction,'both')
            sizeB(k) = size(a,k) + 2*padSize(k);
        else
            sizeB(k) = size(a,k) + padSize(k);
        end
    end
    
    b = mkconstarray(class(a), padVal, sizeB);
    
elseif strcmpi(method,'constant')
    
    % constant value padding with padVal
    b = ConstantPad(a, padSize, padVal, direction);
else
    
    % compute indices then index into input image
    aSize = size(a);
    aIdx = getPaddingIndices(aSize,padSize,method,direction);
    b = a(aIdx{:});
end

if islogical(a)
    b = logical(b);
end

%%%
%%% ConstantPad
%%%
function b = ConstantPad(a, padSize, padVal, direction)

numDims = numel(padSize);

% Form index vectors to subsasgn input array into output array.
% Also compute the size of the output array.
idx   = cell(1,numDims);
sizeB = zeros(1,numDims);
for k = 1:numDims
    M = size(a,k);
    switch direction
        case 'pre'
            idx{k}   = (1:M) + padSize(k);
            sizeB(k) = M + padSize(k);
            
        case 'post'
            idx{k}   = 1:M;
            sizeB(k) = M + padSize(k);
            
        case 'both'
            idx{k}   = (1:M) + padSize(k);
            sizeB(k) = M + 2*padSize(k);
    end
end

% Initialize output array with the padding value.  Make sure the
% output array is the same type as the input.
b         = mkconstarray(class(a), padVal, sizeB);
b(idx{:}) = a;

function out = mkconstarray(class, value, size)
%MKCONSTARRAY creates a constant array of a specified numeric class.
%   A = MKCONSTARRAY(CLASS, VALUE, SIZE) creates a constant array 
%   of value VALUE and of size SIZE.

%   Copyright 1993-2013 The MathWorks, Inc.  

out = repmat(feval(class, value), size);

function aIdx = getPaddingIndices(aSize,padSize,method,direction)
%getPaddingIndices is used by padarray and blockproc. 
%   Computes padding indices of input image.  This is function is used to
%   handle padding of in-memory images (via padarray) as well as
%   arbitrarily large images (via blockproc).
%
%   aSize : result of size(I) where I is the image to be padded
%   padSize : padding amount in each dimension.  
%             numel(padSize) can be greater than numel(aSize)
%   method : X or a 'string' padding method
%   direction : pre, post, or both.
%
%   See the help for padarray for additional information.

% Copyright 2010 The MathWorks, Inc.

% make sure we have enough image dims for the requested padding
if numel(padSize) > numel(aSize)
    singleton_dims = numel(padSize) - numel(aSize);
    aSize = [aSize ones(1,singleton_dims)];
end

switch method
    case 'circular'
        aIdx = CircularPad(aSize, padSize, direction);
    case 'symmetric'
        aIdx = SymmetricPad(aSize, padSize, direction);
    case 'replicate' 
        aIdx = ReplicatePad(aSize, padSize, direction);
end


%%%
%%% CircularPad
%%%
function idx = CircularPad(aSize, padSize, direction)

numDims = numel(padSize);

% Form index vectors to subsasgn input array into output array.
% Also compute the size of the output array.
idx   = cell(1,numDims);
for k = 1:numDims
    M = aSize(k);
    dimNums = uint32(1:M);
    p = padSize(k);
    
    switch direction
        case 'pre'
            idx{k}   = dimNums(mod(-p:M-1, M) + 1);
            
        case 'post'
            idx{k}   = dimNums(mod(0:M+p-1, M) + 1);
            
        case 'both'
            idx{k}   = dimNums(mod(-p:M+p-1, M) + 1);
            
    end
end


%%%
%%% SymmetricPad
%%%
function idx = SymmetricPad(aSize, padSize, direction)

numDims = numel(padSize);

% Form index vectors to subsasgn input array into output array.
% Also compute the size of the output array.
idx   = cell(1,numDims);
for k = 1:numDims
    M = aSize(k);
    dimNums = uint32([1:M M:-1:1]);
    p = padSize(k);
    
    switch direction
        case 'pre'
            idx{k}   = dimNums(mod(-p:M-1, 2*M) + 1);
            
        case 'post'
            idx{k}   = dimNums(mod(0:M+p-1, 2*M) + 1);
            
        case 'both'
            idx{k}   = dimNums(mod(-p:M+p-1, 2*M) + 1);
    end
end


%%%
%%% ReplicatePad
%%%
function idx = ReplicatePad(aSize, padSize, direction)

numDims = numel(padSize);

% Form index vectors to subsasgn input array into output array.
% Also compute the size of the output array.
idx   = cell(1,numDims);
for k = 1:numDims
    M = aSize(k);
    p = padSize(k);
    onesVector = uint32(ones(1,p));
    
    switch direction
        case 'pre'
            idx{k}   = [onesVector 1:M];
            
        case 'post'
            idx{k}   = [1:M M*onesVector];
            
        case 'both'
            idx{k}   = [onesVector 1:M M*onesVector];
    end
end


