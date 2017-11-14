function y = filtfilt_(b,a,x)
%FILTFILT Zero-phase forward and reverse digital IIR filtering.
%   Y = FILTFILT(B, A, X) filters the data in vector X with the filter
%   described by vectors A and B to create the filtered data Y.  The filter
%   is described by the difference equation:
%
%     a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
%                           - a(2)*y(n-1) - ... - a(na+1)*y(n-na)
%
%   The length of the input X must be more than three times the filter
%   order, defined as max(length(B)-1,length(A)-1).
%
%   Y = FILTFILT(SOS, G, X) filters the data in vector X with the
%   second-order section (SOS) filter described by the matrix SOS and the
%   vector G.  The coefficients of the SOS matrix must be expressed using
%   an Lx6 matrix where L is the number of second-order sections. The scale
%   values of the filter must be expressed using the vector G. The length
%   of G must be between 1 and L+1, and the length of input X must be more
%   than three times the filter order (input length must be greater than
%   one when the order is zero). You can use filtord(SOS) to get the
%   order of the filter. The SOS matrix should have the following form:
%
%   SOS = [ b01 b11 b21 a01 a11 a21
%           b02 b12 b22 a02 a12 a22
%           ...
%           b0L b1L b2L a0L a1L a2L ]
%
%   Y = FILTFILT(D, X) filters the data in vector X with the digital filter
%   D. You design a digital filter, D, by calling the <a href="matlab:help designfilt">designfilt</a> function.
%   The length of the input X must be more than three times the filter
%   order. You can use filtord(D) to get the order of the digital filter D.
%
%   After filtering in the forward direction, the filtered sequence is then
%   reversed and run back through the filter; Y is the time reverse of the
%   output of the second filtering operation.  The result has precisely
%   zero phase distortion, and magnitude modified by the square of the
%   filter's magnitude response. Startup and ending transients are
%   minimized by matching initial conditions.
%
%   Note that FILTFILT should not be used when the intent of a filter is to
%   modify signal phase, such as differentiators and Hilbert filters.
%
%   % Example 1:
%   %   Zero-phase filter a noisy ECG waveform using an IIR filter.
%  
%   x = ecg(500)'+0.25*randn(500,1);        % noisy waveform
%   [b,a] = butter(12,0.2,'low');           % IIR filter design
%   y = filtfilt(b,a,x);                    % zero-phase filtering
%   y2 = filter(b,a,x);                     % conventional filtering
%   plot(x,'k-.'); grid on ; hold on
%   plot([y y2],'LineWidth',1.5);
%   legend('Noisy ECG','Zero-phase Filtering','Conventional Filtering');
%
%   % Example 2:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 4, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Sample rate is 200 KHz. Apply zero-phase filtering to a
%   %   vector of data. 
%  
%   D = designfilt('highpassiir', 'FilterOrder', 4, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   x = rand(1000,1);
%   y = filtfilt(D,x);
%
%   See also FILTER, SOSFILT.

%   References:
%     [1] Sanjit K. Mitra, Digital Signal Processing, 2nd ed.,
%         McGraw-Hill, 2001
%     [2] Fredrik Gustafsson, Determining the initial states in forward-
%         backward filtering, IEEE Transactions on Signal Processing,
%         pp. 988-992, April 1996, Volume 44, Issue 4

%   Copyright 1988-2014 The MathWorks, Inc.

narginchk(3,3)

% Only double precision is supported
if ~isa(b,'double') || ~isa(a,'double') || ~isa(x,'double')
    error(('signal:filtfilt:NotSupported'));
end
if isempty(b) || isempty(a) || isempty(x)
    y = [];
    return
end

% If input data is a row vector, convert it to a column
isRowVec = size(x,1)==1;
if isRowVec
    x = x(:);
end
[Npts,Nchans] = size(x);

% Parse SOS matrix or coefficients vectors and determine initial conditions
[b,a,zi,nfact,L] = getCoeffsAndInitialConditions_(b,a,Npts);

% Filter the data
if Nchans==1
    if Npts<10000
        y = ffOneChanCat_(b,a,x,zi,nfact,L);
    else
        y = ffOneChan_(b,a,x,zi,nfact,L);
    end
else
    y = ffMultiChan_(b,a,x,zi,nfact,L);
end

if isRowVec
    y = y.';   % convert back to row if necessary
end

%--------------------------------------------------------------------------
function [b,a,zi,nfact,L] = getCoeffsAndInitialConditions_(b,a,Npts)

[L, ncols] = size(b);
na = numel(a);

% Rules for the first two inputs to represent an SOS filter:
% b is an Lx6 matrix with L>1 or,
% b is a 1x6 vector, its 4th element is equal to 1 and a has less than 2
% elements. 
if ncols==6 && L==1 && na<=2,
    if b(4)==1,
        warning(message('signal:filtfilt:ParseSOS', 'SOS', 'G'));
    else
        warning(message('signal:filtfilt:ParseB', 'a01', 'SOS'));
    end
end
issos = ncols==6 && (L>1 || (b(4)==1 && na<=2));
if issos,
    %----------------------------------------------------------------------
    % b is an SOS matrix, a is a vector of scale values
    %----------------------------------------------------------------------
    g = a(:);
    ng = na;
    if ng>L+1,
        error(message('signal:filtfilt:InvalidDimensionsScaleValues', L + 1));
    elseif ng==L+1,
        % Include last scale value in the numerator part of the SOS Matrix
        b(L,1:3) = g(L+1)*b(L,1:3);
        ng = ng-1;
    end
    for ii=1:ng,
        % Include scale values in the numerator part of the SOS Matrix
        b(ii,1:3) = g(ii)*b(ii,1:3);
    end
    
    ord = filtord_(b);
    
    a = b(:,4:6).';
    b = b(:,1:3).';
         
    nfact = max(1,3*ord); % length of edge transients    
    if Npts <= nfact % input data too short
        error(message('signal:filtfilt:InvalidDimensionsDataShortForFiltOrder',num2str(nfact)))
    end
    
    % Compute initial conditions to remove DC offset at beginning and end of
    % filtered sequence.  Use sparse matrix to solve linear system for initial
    % conditions zi, which is the vector of states for the filter b(z)/a(z) in
    % the state-space formulation of the filter.
    zi = zeros(2,L);
    for ii=1:L,
        rhs  = (b(2:3,ii) - b(1,ii)*a(2:3,ii));
        zi(:,ii) = ( eye(2) - [-a(2:3,ii),[1;0]] ) \ rhs;
    end
    
else
    %----------------------------------------------------------------------
    % b and a are vectors that define the transfer function of the filter
    %----------------------------------------------------------------------
    L = 1;
    % Check coefficients
    b = b(:);
    a = a(:);
    nb = numel(b);
    nfilt = max(nb,na);   
    nfact = max(1,3*(nfilt-1));  % length of edge transients
    if Npts <= nfact      % input data too short
        error('signal:filtfilt:InvalidDimensionsDataShortForFiltOrder',num2str(nfact));
    end
    % Zero pad shorter coefficient vector as needed
    if nb < nfilt
        b(nfilt,1)=0;
    elseif na < nfilt
        a(nfilt,1)=0;
    end
    
    % Compute initial conditions to remove DC offset at beginning and end of
    % filtered sequence.  Use sparse matrix to solve linear system for initial
    % conditions zi, which is the vector of states for the filter b(z)/a(z) in
    % the state-space formulation of the filter.
    if nfilt>1
        rows = [1:nfilt-1, 2:nfilt-1, 1:nfilt-2];
        cols = [ones(1,nfilt-1), 2:nfilt-1, 2:nfilt-1];
        vals = [1+a(2), a(3:nfilt).', ones(1,nfilt-2), -ones(1,nfilt-2)];
        rhs  = b(2:nfilt) - b(1)*a(2:nfilt);
        zi   = sparse(rows,cols,vals) \ rhs;
        % The non-sparse solution to zi may be computed using:
        %      zi = ( eye(nfilt-1) - [-a(2:nfilt), [eye(nfilt-2); ...
        %                                           zeros(1,nfilt-2)]] ) \ ...
        %          ( b(2:nfilt) - b(1)*a(2:nfilt) );
    else
        zi = zeros(0,1);
    end
end
%--------------------------------------------------------------------------
function y = ffOneChanCat_(b,a,y,zi,nfact,L)

for ii=1:L
    % Single channel, data explicitly concatenated into one vector
    y = [2*y(1)-y(nfact+1:-1:2); y; 2*y(end)-y(end-1:-1:end-nfact)]; %#ok<AGROW>
    
    % filter, reverse data, filter again, and reverse data again
    y = filter(b(:,ii),a(:,ii),y,zi(:,ii)*y(1));
    y = y(end:-1:1);
    y = filter(b(:,ii),a(:,ii),y,zi(:,ii)*y(1));
    
    % retain reversed central section of y
    y = y(end-nfact:-1:nfact+1);
end

%--------------------------------------------------------------------------
function y = ffOneChan_(b,a,xc,zi,nfact,L)
% Perform filtering of input data with no phase distortion
%
% xc: one column of input data
% yc: one column of output, same dimensions as xc
% a,b: IIR coefficients, both of same order/length
% zi: initial states
% nfact: scalar
% L: scalar

% Extrapolate beginning and end of data sequence using reflection.
% Slopes of original and extrapolated sequences match at end points,
% reducing transients.
%
% yc is length numel(x)+2*nfact
%
% We wish to filter the appended sequence:
% yc = [2*xc(1)-xc(nfact+1:-1:2); xc; 2*xc(end)-xc(end-1:-1:end-nfact)];
%
% We would use the following code:
% Filter the input forwards then again in the backwards direction
%   yc = filter(b,a,yc,zi*yc(1));
%   yc = yc(length(yc):-1:1); % reverse the sequence
%
% Instead of reallocating and copying, just do filtering in pieces
% Filter the first part, then xc, then the last part
% Retain each piece, feeding final states as next initial states
% Output is yc = [yc1 yc2 yc3]
%
% yc2 can be long (matching user input length)
% yc3 is short (nfilt samples)
%
for ii=1:L
    
    xt = -xc(nfact+1:-1:2) + 2*xc(1);
    [~,zo] = filter(b(:,ii),a(:,ii), xt, zi(:,ii)*xt(1)); % yc1 not needed
    [yc2,zo] = filter(b(:,ii),a(:,ii), xc, zo);
    xt = -xc(end-1:-1:end-nfact) + 2*xc(end);
    yc3 = filter(b(:,ii),a(:,ii), xt, zo);
    
    % Reverse the sequence
    %   yc = [flipud(yc3) flipud(yc2) flipud(yc1)]
    % which we can do as
    %   yc = [yc3(end:-1:1); yc2(end:-1:1); yc1(end:-1:1)];
    %
    % But we don't do that explicitly.  Instead, we wish to filter this
    % reversed result as in:
    %   yc = filter(b,a,yc,zi*yc(1));
    % where yc(1) is now the last sample of the (unreversed) yc3
    %
    % Once again, we do this in pieces:
    [~,zo] = filter(b(:,ii),a(:,ii), yc3(end:-1:1), zi(:,ii)*yc3(end));
    yc5 = filter(b(:,ii),a(:,ii), yc2(end:-1:1), zo);
    
    % Conceptually restore the sequence by reversing the last pieces
    %    yc = yc(length(yc):-1:1); % restore the sequence
    % which is done by
    %    yc = [yc6(end:-1:1); yc5(end:-1:1); yc4(end:-1:1)];
    %
    % However, we only need to retain the reversed central samples of filtered
    % output for the final result:
    %    y = yc(nfact+1:end-nfact);
    %
    % which is the reversed yc5 piece only.
    %
    % This means we don't need yc4 or yc6.  We need to compute yc4 only because
    % the final states are needed for yc5 computation.  However, we can omit
    % yc6 entirely in the above filtering step.
    xc = yc5(end:-1:1);
end
y = xc;

%--------------------------------------------------------------------------
function y = ffMultiChan_(b,a,xc,zi,nfact,L)
% Perform filtering of input data with no phase distortion
%
% xc: matrix of input data
% yc: matrix of output data, same dimensions as xc
% a,b: IIR coefficients, both of same order/length
% zi: initial states
% nfact: scalar
% L: scalar

% Same comments as in ffOneChan, except here we need to use bsxfun.
% Instead of doing scalar subtraction with a vector, we are doing
% vector addition with a matrix.  bsxfun replicates the vector
% for us.
%
% We also take care to preserve column dimensions
%
sz = size(xc);
xc = reshape(xc,sz(1),[]);%converting N-D matrix to 2-D.

for ii=1:L
    xt = bsxfun(@minus, 2*xc(1,:), xc(nfact+1:-1:2,:));
    [~,zo] = filter(b(:,ii),a(:,ii),xt,zi(:,ii)*xt(1,:)); % outer product
    [yc2,zo] = filter(b(:,ii),a(:,ii),xc,zo);
    xt = bsxfun(@minus, 2*xc(end,:), xc(end-1:-1:end-nfact,:));
    yc3 = filter(b(:,ii),a(:,ii),xt,zo);
    
    [~,zo] = filter(b(:,ii),a(:,ii),yc3(end:-1:1,:),zi(:,ii)*yc3(end,:)); % outer product
    yc5 = filter(b(:,ii),a(:,ii),yc2(end:-1:1,:), zo);
    
    xc = yc5(end:-1:1,:);
end
y = xc;
y = reshape(y,sz);% To match the input size.

function n = filtord_(b,varargin)
%FILTORD Filter order
%   N = FILTORD(B,A) returns the order, N, of the filter:
%
%               jw               -jw              -jmw
%        jw  B(e)    b(1) + b(2)e + .... + b(m+1)e
%     H(e) = ---- = ------------------------------------
%               jw               -jw              -jnw
%            A(e)    a(1) + a(2)e + .... + a(n+1)e
%
%   given numerator and denominator coefficients in vectors B and A. 
%
%   N = FILTORD(SOS) returns order, N, of the filter specified using the
%   second order sections matrix SOS. SOS is a Kx6 matrix, where the number
%   of sections, K, must be greater than or equal to 2. Each row of SOS
%   corresponds to the coefficients of a second order filter. From the
%   transfer function displayed above, the ith row of the SOS matrix
%   corresponds to [bi(1) bi(2) bi(3) ai(1) ai(2) ai(3)].
%
%   N = FILTORD(D) returns order, N, of the digital filter D. You design a
%   digital filter, D, by calling the <a href="matlab:help designfilt">designfilt</a> function.
%
%   % Example 1:
%   %   Create a 25th-order lowpass FIR filter and verify its order using 
%   %   filtord.
%
%   b = fir1(25,0.45);
%   n = filtord(b)    
%
%   % Example 2:
%   %   Create a 6th-order lowpass IIR filter using second order sections
%   %   and verify its order using filtord.
%
%   [z,p,k] = butter(6,0.35);
%   SOS = zp2sos(z,p,k);	% second order sections matrix
%   n = filtord(SOS)	    
%
%   % Example 3:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 8, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Use filtord to get the filter order. 
%  
%   D = designfilt('highpassiir', 'FilterOrder', 8, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   n = filtord(D)
%
%   See also FVTOOL, ISALLPASS, ISLINPHASE, ISMAXPHASE, ISMINPHASE, ISSTABLE

%   Copyright 2012-2013 The MathWorks, Inc.

narginchk(1,2);

a = 1; % Assume FIR for now

if all(size(b)>[1 1])
  % Input is a matrix, check if it is a valid SOS matrix
  if size(b,2) ~= 6
    error(message('signal:signalanalysisbase:invalidinputsosmatrix'));
  end
  if nargin > 1
    error(message('signal:signalanalysisbase:invalidNumInputs'));
  end
  
  [b,a] = sos2tf_(b); % get transfer function
  
elseif ~isempty(varargin)
  
  a = varargin{1};
  
  if all(size(a)>[1 1])
    error(message('signal:signalanalysisbase:inputnotsupported'));
  end
end

if ~isempty(b) && max(abs(b))~=0
  b = b/max(abs(b));
end
if ~isempty(a) && max(abs(a))~=0
  a = a/max(abs(a));
end

% Remove trailing "zeros" of a & b.
if ~isempty(b)
  b = b(1:find(b~=0, 1, 'last' ));
end
if ~isempty(a)
  a = a(1:find(a~=0, 1, 'last' ));
end

n = max(length(b),length(a)) - 1;

function [b,a] = sos2tf_(sos_,g)
%SOS2TF 2nd-order sections to transfer function model conversion.
%   [B,A] = SOS2TF(SOS,G) returns the numerator and denominator
%   coefficients B and A of the discrete-time linear system given
%   by the gain G and the matrix SOS in second-order sections form.
%
%   SOS is an L by 6 matrix which contains the coefficients of each
%   second-order section in its rows:
%       SOS = [ b01 b11 b21  1 a11 a21
%               b02 b12 b22  1 a12 a22
%               ...
%               b0L b1L b2L  1 a1L a2L ]
%   The system transfer function is the product of the second-order
%   transfer functions of the sections times the gain G. If G is not
%   specified, it defaults to 1. Each row of the SOS matrix describes
%   a 2nd order transfer function as
%       b0k +  b1k z^-1 +  b2k  z^-2
%       ----------------------------
%       1 +  a1k z^-1 +  a2k  z^-2
%   where k is the row index.
%
%   % Example:
%   %   Compute the transfer function representation of a simple second-
%   %   -order section system.
%
%   sos = [1  1  1  1  0 -1; -2  3  1  1 10  1];
%   [b,a] = sos2tf(sos)
%
%   See also ZP2SOS, SOS2ZP, SOS2SS, SS2SOS

%   Copyright 1988-2013 The MathWorks, Inc.

narginchk(1,2)

if nargin == 1,
    g = 1;
end
% Cast to enforce Precision Rules
% if any([signal.internal.sigcheckfloattype(sos,'single','sos2tf','SOS')...
%     signal.internal.sigcheckfloattype(g,'single','sos2tf','G')])
%   sos = single(sos);
%   g = single(g);
% end

[L,n] = size(sos_);
if n ~= 6,
    error(message('signal:sos2tf:InvalidDimensions'));
end

if L == 0,
    b = [];
    a = [];
    return
end

b = 1;
a = 1;
for m=1:L,
    b1 = sos_(m,1:3);
    a1 = sos_(m,4:6);
    b = conv(b,b1);
    a = conv(a,a1);
end
b = b.*prod(g);
if length(b) > 3,
    if b(end) == 0,
        b(end) = []; % Remove trailing zeros if any for order > 2
    end
end
if length(a) > 3,
    if a(end) == 0,
        a(end) = []; % Remove trailing zeros if any for order > 2
    end
end

