function [hh,w,s,options] = freqz_(b,varargin)
%FREQZ Frequency response of digital filter
%   [H,W] = FREQZ(B,A,N) returns the N-point complex frequency response
%   vector H and the N-point frequency vector W in radians/sample of
%   the filter:
%
%               jw               -jw              -jmw
%        jw  B(e)    b(1) + b(2)e + .... + b(m+1)e
%     H(e) = ---- = ------------------------------------
%               jw               -jw              -jnw
%            A(e)    a(1) + a(2)e + .... + a(n+1)e
%
%   given numerator and denominator coefficients in vectors B and A.
%
%   [H,W] = FREQZ(SOS,N) returns the N-point complex frequency response
%   given the second order sections matrix SOS. SOS is a Kx6 matrix, where
%   the number of sections, K, must be greater than or equal to 2. Each row
%   of SOS corresponds to the coefficients of a second order filter. From
%   the transfer function displayed above, the ith row of the SOS matrix
%   corresponds to [bi(1) bi(2) bi(3) ai(1) ai(2) ai(3)].
%
%   [H,W] = FREQZ(D,N) returns the N-point complex frequency response given
%   the digital filter, D. You design a digital filter, D, by calling the
%   <a href="matlab:help designfilt">designfilt</a> function.
%
%   In all cases, the frequency response is evaluated at N points equally
%   spaced around the upper half of the unit circle. If N isn't specified,
%   it defaults to 512.
%
%   [H,W] = FREQZ(...,N,'whole') uses N points around the whole unit
%   circle.
%
%   H = FREQZ(...,W) returns the frequency response at frequencies
%   designated in vector W, in radians/sample (normally between 0 and pi).
%   W must be a vector with at least two elements.
%
%   [H,F] = FREQZ(...,N,Fs) and [H,F] = FREQZ(...,N,'whole',Fs) return
%   frequency vector F (in Hz), where Fs is the sampling frequency (in Hz).
%
%   H = FREQZ(...,F,Fs) returns the complex frequency response at the
%   frequencies designated in vector F (in Hz), where Fs is the sampling
%   frequency (in Hz).
%
%   FREQZ(...) with no output arguments plots the magnitude and
%   unwrapped phase of the filter in the current figure window.
%
%   % Example 1:
%   %   Design a lowpass FIR filter with normalized cut-off frequency at
%   %   0.3 and determine its frequency response.
%
%   b=fircls1(54,0.3,0.02,0.008);
%   freqz(b)
%
%   % Example 2:
%   %   Design a 5th order lowpass elliptic IIR filter and determine its
%   %   frequency response.
%
%   [b,a] = ellip(5,0.5,20,0.4);
%   freqz(b,a);
%
%   % Example 3:
%   %   Design a Butterworth highpass IIR filter, represent its coefficients
%   %   using second order sections, and display its frequency response.
%
%   [z,p,k] = butter(6,0.7,'high');
%   SOS = zp2sos(z,p,k);
%   freqz(SOS)
%
%   % Example 4:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 8, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Sample rate is 200 KHz. Visualize the filter response 
%   %   using 2048 frequency points.
%  
%   D = designfilt('highpassiir', 'FilterOrder', 8, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   freqz(D,2048)
%
%   See also FILTER, FFT, INVFREQZ, FVTOOL, and FREQS.

%   Copyright 1988-2013 The MathWorks, Inc.

narginchk(1,5);

a = 1; % Assume FIR for now
isTF = true; % True if dealing with a transfer function

if all(size(b)>[1 1])
    % Input is a matrix, check if it is a valid SOS matrix
    if size(b,2) ~= 6
        error(message('signal:signalanalysisbase:invalidinputsosmatrix'));
    end
    % Checks if SOS is a valid numeric data input
%     signal.internal.sigcheckfloattype(b,'','freqz','SOS');
    
    isTF = false; % SOS instead of transfer function
end

if isTF
    if nargin > 1
        a = varargin{1};
        varargin(1) = [];
    end
    
    if all(size(a)>[1 1])
        error(message('signal:signalanalysisbase:inputnotsupported'));
    end
end

options = freqz_options_(varargin{:});


if isTF
% Checks if B and A are valid numeric data inputs
% signal.internal.sigcheckfloattype(b,'','freqz','B');
% signal.internal.sigcheckfloattype(a,'','freqz','A');

    if length(a) == 1
        [h,w,options] = firfreqz_(b/a,options);
    else
        [h,w,options] = iirfreqz_(b,a,options);
    end
else
    validateattributes(b,{'double','single'},{},'freqz');   
    [h,w,options] = sosfreqz_(b,options);
end

% Generate the default structure to pass to freqzplot
s = struct;
s.plot = 'both';
s.fvflag = options.fvflag;
s.yunits = 'db';
s.xunits = 'rad/sample';
s.Fs     = options.Fs; % If rad/sample, Fs is empty
if ~isempty(options.Fs),
    s.xunits = 'Hz';
end

% Plot when no output arguments are given
if nargout == 0
    if isTF
        phi = phasez_(b,a,varargin{:});
    else
        phi = phasez_(b,varargin{:});
    end
    
    data(:,:,1) = h;
    data(:,:,2) = phi;
    ws = warning('off'); %#ok<WNOFF>
    freqzplot_(data,w,s,'magphase');
    warning(ws);
    
else
    hh = h;
    if isa(h,'single')
      % Cast to enforce precision rules. Cast when output is requested.
      % Otherwise, plot using double precision frequency vector. 
      w = single(w);
    end
end

%--------------------------------------------------------------------------
function [h,w,options] = firfreqz_(b,options)

% Make b a row
b = b(:).';
n  = length(b);

w      = options.w;
Fs     = options.Fs;
nfft   = options.nfft;
fvflag = options.fvflag;

% Actual Frequency Response Computation
if fvflag,
    %   Frequency vector specified.  Use Horner's method of polynomial
    %   evaluation at the frequency points and divide the numerator
    %   by the denominator.
    %
    %   Note: we use positive i here because of the relationship
    %            polyval(a,exp(1i*w)) = fft(a).*exp(1i*w*(length(a)-1))
    %               ( assuming w = 2*pi*(0:length(a)-1)/length(a) )
    %
    if ~isempty(Fs), % Fs was specified, freq. vector is in Hz
        digw = 2.*pi.*w./Fs; % Convert from Hz to rad/sample for computational purposes
    else
        digw = w;
    end
    
    s = exp(1i*digw); % Digital frequency must be used for this calculation
    h = polyval(b,s)./exp(1i*digw*(n-1));
else
    % freqvector not specified, use nfft and RANGE in calculation
    s = find(strncmpi(options.range, {'twosided','onesided'}, length(options.range)));
    
    if s*nfft < n,
        % Data is larger than FFT points, wrap modulo s*nfft
        b = datawrap_(b,s.*nfft);
    end
    
    % dividenowarn temporarily shuts off warnings to avoid "Divide by zero"
    h = fft(b,s.*nfft).';
    % When RANGE = 'half', we computed a 2*nfft point FFT, now we take half the result
    h = h(1:nfft);
    h = h(:); % Make it a column only when nfft is given (backwards comp.)
    w = freqz_freqvec_(nfft, Fs, s);
    w = w(:); % Make it a column only when nfft is given (backwards comp.)
end

%--------------------------------------------------------------------------
function [h,w,options] = iirfreqz_(b,a,options)
% Make b and a rows
b = b(:).';
a = a(:).';

nb = length(b);
na = length(a);
a  = [a zeros(1,nb-na)];  % Make a and b of the same length
b  = [b zeros(1,na-nb)];
n  = length(a); % This will be the new length of both num and den

w      = options.w;
Fs     = options.Fs;
nfft   = options.nfft;
fvflag = options.fvflag;

% Actual Frequency Response Computation
if fvflag,
    %   Frequency vector specified.  Use Horner's method of polynomial
    %   evaluation at the frequency points and divide the numerator
    %   by the denominator.
    %
    %   Note: we use positive i here because of the relationship
    %            polyval(a,exp(1i*w)) = fft(a).*exp(1i*w*(length(a)-1))
    %               ( assuming w = 2*pi*(0:length(a)-1)/length(a) )
    %
    if ~isempty(Fs), % Fs was specified, freq. vector is in Hz
        digw = 2.*pi.*w./Fs; % Convert from Hz to rad/sample for computational purposes
    else
        digw = w;
    end
    
    s = exp(1i*digw); % Digital frequency must be used for this calculation
    h = polyval(b,s) ./ polyval(a,s);
else
    % freqvector not specified, use nfft and RANGE in calculation
    s = find(strncmpi(options.range, {'twosided','onesided'}, length(options.range)));
    
    if s*nfft < n,
        % Data is larger than FFT points, wrap modulo s*nfft
        b = datawrap_(b,s.*nfft);
        a = datawrap_(a,s.*nfft);
    end
    
    % dividenowarn temporarily shuts off warnings to avoid "Divide by zero"
    h = dividenowarn_(fft(b,s.*nfft),fft(a,s.*nfft)).';
    % When RANGE = 'half', we computed a 2*nfft point FFT, now we take half the result
    h = h(1:nfft);
    h = h(:); % Make it a column only when nfft is given (backwards comp.)
    w = freqz_freqvec_(nfft, Fs, s);
    w = w(:); % Make it a column only when nfft is given (backwards comp.)
end
%--------------------------------------------------------------------------
function [h,w,options] = sosfreqz_(sos_,options)

[h, w] = iirfreqz_(sos_(1,1:3), sos_(1,4:6), options);
for indx = 2:size(sos_, 1)
    h = h.*iirfreqz_(sos_(indx,1:3), sos_(indx,4:6), options);
end

%-------------------------------------------------------------------------------
function [options] = freqz_options_(varargin)
%FREQZ_OPTIONS   Parse the optional arguments to FREQZ.
%   FREQZ_OPTIONS returns a structure with the following fields:
%   options.nfft         - number of freq. points to be used in the computation
%   options.fvflag       - Flag indicating whether nfft was specified or a vector was given
%   options.w            - frequency vector (empty if nfft is specified)
%   options.Fs           - Sampling frequency (empty if no Fs specified)
%   options.range        - 'half' = [0, Nyquist); 'whole' = [0, 2*Nyquist)


% Set up defaults
options.nfft   = varargin{1};
options.Fs     = [];
options.w      = [];
options.range  = 'onesided';
options.fvflag = 0;
isreal_x       = []; % Not applicable to freqz

% [options,msg,msgobj] = psdoptions(isreal_x,options,varargin{:});

% Cast to enforce precision rules
options.nfft = double(options.nfft);
options.Fs = double(options.Fs);
options.w = double(options.w);
options.fvflag = double(options.fvflag);

if any(size(options.nfft)>1),
    % frequency vector given, may be linear or angular frequency
    options.w = options.nfft;
    options.fvflag = 1;
end

% [EOF] freqz.m

function y = dividenowarn_(num,den)
% DIVIDENOWARN Divides two polynomials while suppressing warnings.
% DIVIDENOWARN(NUM,DEN) array divides two polynomials but suppresses warnings 
% to avoid "Divide by zero" warnings.

%   Copyright 1988-2002 The MathWorks, Inc.

s = warning; % Cache warning state
warning off  % Avoid "Divide by zero" warnings
y = (num./den);
warning(s);  % Reset warning state

% [EOF] dividenowarn.m

function w = freqz_freqvec_(nfft, Fs, s)
%FREQZ_FREQVEC Frequency vector for calculating filter responses.
%   This is a helper function intended to be used by FREQZ.
%
%   Inputs:
%       nfft    -   The number of points
%       Fs      -   The sampling frequency of the filter
%       s       -   1 = 0-2pi, 2 = 0-pi, 3 = -pi-pi

%   Author(s): J. Schickler
%   Copyright 1988-2004 The MathWorks, Inc.

if nargin < 2,  Fs = []; end
if nargin < 3,  s  = 2; end
if isempty(Fs), Fs = 2*pi; end

switch s
    case 1,  % 0-2pi
        deltaF = Fs/nfft;
        w = linspace(0,Fs-deltaF,nfft);
        
        % There can still be some minor round off errors.  Fix the known points,
        % those near pi and 2pi.
        if rem(nfft, 2)
            w((nfft+1)/2) = Fs/2-Fs/(2*nfft);
            w((nfft+1)/2+1) = Fs/2+Fs/(2*nfft);
        else
            % Make sure we hit Fs/2 exactly for the 1/2 nyquist point.
            w(nfft/2+1) = Fs/2;
        end
        w(nfft) = Fs-Fs/nfft;

    case 2,  % 0-pi
        deltaF = Fs/2/nfft;
        w = linspace(0,Fs/2-deltaF,nfft);
        
        w(nfft) = Fs/2-Fs/2/nfft;
        
    case 3, % -pi-pi
        deltaF = Fs/nfft;
        
        if rem(nfft,2), % ODD, don't include Nyquist.
            wmin = -(Fs - deltaF)/2;
            wmax = (Fs - deltaF)/2;
            
        else            % EVEN include Nyquist point in the negative freq.
            wmin = -Fs/2;
            wmax = Fs/2 - deltaF;
        end
        w = linspace(wmin, wmax, nfft);
        if rem(nfft, 2) % ODD
            w((nfft+1)/2) = 0;
        else
            w(nfft/2+1) = 0;
        end
end

% [EOF]

function varargout = phasez_(b,varargin)
%PHASEZ Phase response of digital filter
%   [PHI,W] = PHASEZ(B,A,N) returns the N-point unwrapped phase response
%   vector PHI and the N-point frequency vector W in radians/sample of
%   the filter:
%               jw               -jw              -jmw
%        jw  B(e)    b(1) + b(2)e + .... + b(m+1)e
%     H(e) = ---- = ------------------------------------
%               jw               -jw              -jnw
%            A(e)    a(1) + a(2)e + .... + a(n+1)e
%   given numerator and denominator coefficients in vectors B and A. 
%
%   [PHI,W] = PHASEZ(SOS,N) returns the N-point unwrapped phase response
%   given the second order sections matrix SOS. SOS is a Kx6 matrix, where
%   the number of sections, K, must be greater than or equal to 2. Each row
%   of SOS corresponds to the coefficients of a second order filter. From
%   the transfer function displayed above, the ith row of the SOS matrix
%   corresponds to [bi(1) bi(2) bi(3) ai(1) ai(2) ai(3)].
%
%   [PHI,W] = PHASEZ(D,N) returns the N-point unwrapped phase response
%   given the digital filter, D. You design a digital filter, D, by calling
%   the <a href="matlab:help designfilt">designfilt</a> function.
%
%   In all cases, the phase response is evaluated at N points equally
%   spaced around the upper half of the unit circle. If N isn't specified,
%   it defaults to 512.
%
%   [PHI,W] = PHASEZ(...,N,'whole') uses N points around the whole unit
%   circle.
%
%   PHI = PHASEZ(...,W) returns the phase response at frequencies
%   designated in vector W, in radians/sample (normally between 0 and pi).
%
%   [PHI,F] = PHASEZ(...,N,Fs) and [PHI,F] = PHASEZ(...,N,'whole',Fs)
%   return phase vector F (in Hz), where Fs is the sampling frequency (in
%   Hz).
%
%   PHI = PHASEZ(...,F,Fs) returns the phase response at the frequencies
%   designated in vector F (in Hz), where Fs is the sampling frequency (in
%   Hz).
%
%   PHASEZ(...) with no output arguments plots the unwrapped phase of
%   the filter.
%
%   % Example 1:
%   %   Design a lowpass FIR filter with normalized cut-off frequency at 
%   %   0.3 and determine its phase response.
%
%   b=fircls1(54,0.3,0.02,0.008);
%   phasez(b)                       
%
%   % Example 2: 
%   %   Design a 5th order lowpass elliptic IIR filter and determine its
%   %   phase response.
%
%   [b,a] = ellip(5,0.5,20,0.4);
%   phasez(b,a,512,'whole');        
%
%   % Example 3:
%   %   Design a Butterworth highpass IIR filter, represent its coefficients
%   %   using second order sections, and display its phase response.
%
%   [z,p,k] = butter(6,0.7,'high');
%   SOS = zp2sos(z,p,k);    
%   phasez(SOS)      
%
%   % Example 4:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 8, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Sample rate is 200 KHz. Visualize the phase response 
%   %   using 2048 frequency points.
%  
%   D = designfilt('highpassiir', 'FilterOrder', 8, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   phasez(D,2048)
%
%   See also FREQZ, PHASEDELAY, GRPDELAY and FVTOOL.

%   Copyright 1988-2013 The MathWorks, Inc.

narginchk(1,5);

a = 1; % Assume FIR for now
isTF = true; % True if dealing with a transfer function

if all(size(b)>[1 1])
  % Input is a matrix, check if it is a valid SOS matrix
  if size(b,2) ~= 6
    error(message('signal:signalanalysisbase:invalidinputsosmatrix'));
  end
  % Checks if SOS is a valid numeric data input
%   signal.internal.sigcheckfloattype(b,'','phasez','SOS');
  isTF = false; % SOS instead of transfer function  
end

if isTF
  if nargin > 1
    a = varargin{1};
    varargin(1) = [];
  end

  if all(size(a)>[1 1])
    error(message('signal:signalanalysisbase:inputnotsupported'));
  end
end

% Define the new N-point frequency vector where the frequency response is evaluated
[upn_or_w, upfactor, iswholerange, options, addpoint] = findfreqvector_(varargin{:});

% Compute the frequency response (freqz)
if isTF
  % Checks if B and A are valid numeric data inputs
  if(~isfloat(b) || ~isfloat(a) )
      error('b\a shold be float');
  end
% % % %   signal.internal.sigcheckfloattype(b,'','phasez','B');
% % % %   signal.internal.sigcheckfloattype(a,'','phasez','A');
   
  % freqz casts inputs without single precision bearing (N, F and Fs) to
  % double
  [h, w, s, options] = freq_z(b, a, upn_or_w, options{:});
  
  % Extract phase from frequency response
  [phi,w] = extract_phase_(h,upn_or_w,iswholerange,upfactor,w,addpoint);
else
  %Compute phase for individual sections, not on the entire SOS matrix to
  %avoid close-to-zero responses. Add phase of individual sections.  
  [h, w, s, options1] = freqz_(b(1,1:3), b(1,4:6), upn_or_w, options{:});
  [phi,w] = extract_phase_(h,upn_or_w,iswholerange,upfactor,w,addpoint);
  for indx = 2:size(b, 1)
    h = freqz_(b(indx,1:3), b(indx,4:6), upn_or_w, options{:});
    phi = phi + extract_phase_(h,upn_or_w,iswholerange,upfactor,w,addpoint);            
  end
  options = options1;
end

% Update options
options.nfft = length(w);
options.w    = w;

if length(a)==1 && length(b)==1,
    % Scalar case
    phi = angle(b/a)*ones(length(phi),1);
end

% Cast to enforce precision rules
% Only cast if output is requested, otherwise, plot using double precision
% frequency vector. 
if nargout > 1 && isa(phi,'single')
  w = single(w);
end

% Parse outputs
switch nargout
    case 0
        % Plot when no output arguments are given
        phaseplot_(phi,w,s);
    case 1
        varargout = {phi};
    case 2
        varargout = {phi,w};
    case 3
        varargout = {phi,w,s};
    case 4
        varargout = {phi,w,s,options};
end

%-------------------------------------------------------------------------------
function phaseplot_(phi,w,s)

% Cell array of the standard frequency units strings (used for the Xlabels)
frequnitstrs = getfrequnitstrs_;
switch lower(s.xunits),
    case 'rad/sample',
        xlab = frequnitstrs{1};
        w    = w./pi; % Scale by pi in the plot
    case 'hz',
        xlab = frequnitstrs{2};
    case 'khz',
        xlab = frequnitstrs{3};
    case 'mhz',
        xlab = frequnitstrs{4};
    case 'ghz',
        xlab = frequnitstrs{5};
    otherwise
        xlab = s.xunits;
end

plot(w,phi);
title(getString(message('signal:phasez:PhaseResponse')));
xlabel(xlab);
ylabel(getString(message('signal:phasez:Phaseradians')));
grid on;

% [EOF]

function [upn_or_w, upfactor, iswholerange, options, addpoint] = findfreqvector_(varargin)
%FINDFREQVECTOR Define the frequency vector where the phase is evaluated.

%   Author(s): V.Pellissier
%   Copyright 2005 The MathWorks, Inc.


% Parse inputs
[n_or_w, options] = extract_norw_(varargin{:});

% Add f=0 if not included in the frequency factor
addpoint = 0;
if length(n_or_w)>1,
    idx = find(n_or_w>=0);
    if isempty(idx),
        % Only negative frequencies
        addpoint = 1;
        n_or_w = [n_or_w,0];
    else
        idx = find(n_or_w<=0);
        if isempty(idx),
            % Only positive frequencies
            addpoint = -1;
            n_or_w = [0,n_or_w];
        end
    end
end

% Define the new N-point frequency vector where the frequency response is evaluated
[upn_or_w, upfactor, iswholerange] = getinterpfrequencies_(n_or_w, varargin{:});

function [n_or_w, options, do_transpose] = extract_norw_(varargin)
%EXTRACT_NORW Deal optional inputs of phasez and zerophase.
%   [N_OR_W, OPTIONS]=EXTRACT_NORW(VARARGIN) return the third input of freqz N_OR_W
%   that can be either nfft or a vector of frequencies where the frequency response 
%   will be evaluated.

%   Author(s): V.Pellissier, R. Losada
%   Copyright 1988-2005 The MathWorks, Inc.

% Default values
n_or_w = 512;
options = {};
do_transpose = false;

if nargin > 0 & isnumeric(varargin{1}) & isreal(varargin{1}),
    if ~isempty(varargin{1})
        n_or_w = varargin{1};
        if length(n_or_w)>1 && size(n_or_w,1)==1 
           do_transpose = true;
        end
        % Force row vector
        n_or_w = n_or_w(:).';
    end
    if nargin>1,
        options = {varargin{2:end}};
    end
else
    options = {varargin{:}};
end


% [EOF]

function [upn_or_w, upfactor, iswholerange, do_transpose] = getinterpfrequencies_(n_or_w, varargin)
%GETINTERPFREQUENCIES  Define the interpolation factor for phasez and zerophase.
%   [UPN_OR_W, UPFACTOR, ISWHOLERANGE] = GETINTERPFREQUENCIES(N_OR_W, VARARGIN) returns
%   the nfft (respectively w frequencies vector) UPN_OR_W to pass to freqz that is 
%   greater than a threshold (2^13), the upsampling factor UPFACTOR and a 
%   the ISWHOLERANGE boolean. 

%   Author(s): V.Pellissier, R. Losada
%   Copyright 1988-2009 The MathWorks, Inc.

% Minimum number of point where the frequenciy response will be evaluated.
threshold = 2^13;

% Determine if the whole range is needed
iswholerange = 0;
if nargin>2 && any(strcmpi('whole', varargin)),
    iswholerange = 1;
end

isn = 0;
N = length(n_or_w);
if length(n_or_w)==1,
    isn = 1;
    N = n_or_w;
end
 
% Default values
upfactor = 1;

% Compute the upfactor
if N<threshold,
    upfactor = ceil(threshold/N);
    if iswholerange,
        upfactor = 2*upfactor;
    end
else
    if iswholerange,
        upfactor = 2;
    end
end
    
do_transpose = false;
if isn,
    upn_or_w = N*upfactor;
else
    % Interpolate w if needed
    w = n_or_w(:);
    
    if upfactor == 1
        upn_or_w = w;
    else
        
        % Originally using interp, but that required 2*L+1 frequencies passed
        % in. This was broken for case when a two element frequencies vector
        % was passed in.
        %         upn_or_w = interp(w, upfactor);
        
        % Add one sample to the end of the w vector so that we can include
        % the last frequency specified by the user in the interpolated w
        % vector.
        w(end+1) = 2*w(end) - w(end-1);
        n = length(w);
        
        % Preallocate for upn_or_w vector
        upn_or_w = zeros(upfactor*(n-1),1);
        for idx = 0:n-2,
            beginIDX = (idx*upfactor)+1;
            endIDX = (idx+1)*upfactor;
            upn_or_w(beginIDX:endIDX,1) = linspace(w(idx+1),w(idx+2), upfactor);
        end
        if size(n_or_w,2)==1
            do_transpose = true;
        end
    end
end

% [EOF]

function [phi,w] = extract_phase_(h,upn_or_w,iswholerange,upfactor,w,addpoint)
%EXTRACT_PHASE Extract phase from frequency response  

%   Author(s): V. Pellissier
%   Copyright 2005 The MathWorks, Inc.

% When h==0, the phase is not defined (introducing NaN's)
h = modify_fresp_(h);

% Unwrap the phase
phi = unwrap_phase_(h,upn_or_w,iswholerange);

% Downsample
phi = downsample_(phi, upfactor);
w = downsample_(w, upfactor);

% Remove additional point
if addpoint==1,
    phi(end)=[];
    w(end)=[];
elseif addpoint==-1,
    phi(1)=[];
    w(1)=[];
end

%-------------------------------------------------------------------------------
function h = modify_fresp_(h)
% When h==0, the phase is not defined (introducing NaN's)

tol = eps^(2/3);
ind = find(abs(h)<=tol);
if ~isempty(ind);
    h(ind)=NaN;
end

%-------------------------------------------------------------------------------
function phi = unwrap_phase_(h,w,iswholerange)

idx = find(w<0);
if isempty(idx),
    % Range only positive frequencies
    phi=unwrap(angle(h));
else
    idx = idx(end);
    % Unwrap negative frequencies
    phi_n=unwrap(angle(h(idx:-1:1)));
    if idx<length(w),
        % Unwrap positive frequencies
        phi_p=unwrap(angle(h(idx+1:end)));
    else
        phi_p = [];
    end
    phi=[phi_n(end:-1:1);phi_p];
end

% [EOF]

function y = downsample_(x,N,varargin)
%DOWNSAMPLE Downsample input signal.
%   DOWNSAMPLE(X,N) downsamples input signal X by keeping every
%   N-th sample starting with the first. If X is a matrix, the
%   downsampling is done along the columns of X.
%
%   DOWNSAMPLE(X,N,PHASE) specifies an optional sample offset.
%   PHASE must be an integer in the range [0, N-1].
%
%   % Example 1:
%   %   Decrease the sampling rate of a sequence by 3.
%
%   x = [1 2 3 4 5 6 7 8 9 10];
%   y = downsample(x,3)
%
%   % Example 2:
%   %   Decrease the sampling rate of the sequence by 3 and add a 
%   %   phase offset of 2.
%
%   x = [1 2 3 4 5 6 7 8 9 10];
%   y = downsample(x,3,2)
%
%   % Example 3:
%   %   Decrease the sampling rate of a matrix by 3.
%
%   x = [1 2 3; 4 5 6; 7 8 9; 10 11 12];
%   y = downsample(x,3)
%
%   See also UPSAMPLE, UPFIRDN, INTERP, DECIMATE, RESAMPLE.

%   Copyright 1988-2002 The MathWorks, Inc.

y = updownsample_(x,N,'Down',varargin{:});

% [EOF] 

function y = updownsample_(x,N,str,varargin)
%UPDOWNSAMPLE Up- or down-sample input signal.
%   UPDOWNSAMPLE(X,N,STR) changes the sample rate of X by a factor
%   of N, as specifiedd by STR ('up' or 'down').
%
%   UPDOWNSAMPLE(X,N,STR,PHASE) specifies an optional sample offset.
%   PHASE must be an integer in the range [0, N-1].

%   Copyright 1988-2013 The MathWorks, Inc.

narginchk(3,4);

% Shift dimension if necessary
siz = size(x);  % Save original size of x (possibly N-D)
[x,nshift] = shiftdim(x);

phase = parseUpDnSample_(str,N,varargin{:});
N = double(N);

switch lower(str),
case 'down',
    % Perform the downsample
    y = x(phase:N:end, :);
case 'up',
    % Perform the upsample
    % n contains the product of the 2nd through ndims(x) sizes for N-D arrays
    [m,n] = size(x);
    y = x(1);
    y(1:m*N*n) = 0; % Don't use zeros() because it doesn't support fi objects
    y = reshape(y,m*N,n);
    y(phase:N:end, :) = reshape(x,m,n);
end
siz(nshift+1) = size(y,1);  % Update sampled dimension
y = shiftdim(y,-nshift);
if length(siz)>2
    y = reshape(y,siz);  % Restore N-D shape
end

% --------------------------------------------------------
function phase = parseUpDnSample_(str,N,varargin)
% parseUpDnSample Parse input arguments and perform error checking.

% Initialize output args.
phase = 0;

if ( ~isnumeric(N) || (length(N) ~=1) || (fix(N) ~= N) || (N < 1) ),
   error(message('signal:updownsample:SigErrSampleFactor', str))
end

if ~isempty(varargin),
   phase = varargin{1};
end

if ( (~isnumeric(phase)) || (fix(phase) ~= phase) || (phase > N-1) || (phase < 0)),
   error(message('signal:updownsample:SigErrOffset', 'N-1'))
end

phase = phase + 1; % Increase phase for 1-based indexing



% [EOF]

function freqzplot_(h,w,s_in,flag)
%FREQZPLOT Plot frequency response data.
%   FREQZPLOT is obsolete.  FREQZPLOT still works but may be
%   removed in the future. Use FVTOOL instead.
% 
%   See also FREQZ, FVTOOL.

%   Author(s): R. Losada and P. Pacheco 
%   Copyright 1988-2004 The MathWorks, Inc.

% warning(message('signal:freqzplot:obsoleteFunction'));

narginchk(2,4);

if nargin>3,
    if strcmpi(flag, 'magphase') || strcmpi(flag, 'zerocontphase'),
        phi = h(:,:,2);
        h = h(:,:,1);
    elseif strcmpi(flag, 'zerophase'),
        hr =h;
    end
end        

% Generate defaults
s.xunits  = 'rad/sample'; 
s.yunits  = 'db';
s.plot    = 'both'; % Magnitude and phase
s.fvflag  = 0;
s.yphase  = 'degrees';
if nargin > 2,
    s = parseOpts_(s,s_in);
end

% Bring the plot to the foreground
if isfield(s,'ax'),
    ax = s.ax;
    hfig = get(ax,'Parent');
    set(hfig,'CurrentAxes',ax);
else
    
    ax = newplot;
    hfig = get(ax, 'Parent');
    figure(hfig);
    
    hc = get(hfig,'Children');
    for idx = 1:numel(hc)
      newplot(hc(idx))
    end  
    
end

[pd,msg,msgobj] = genplotdata_(h,w,s); % Generate the plot data
if ~isempty(msg), error(msgobj); end

switch s.plot,
case 'mag',
    if nargin>3 & strcmpi(flag, 'zerophase'), %#ok
        pd.magh = hr;
        pd.magh = [pd.magh;inf*ones(1,size(pd.magh,2))];
        if length(pd.w)<size(pd.magh,2),
            pd.w = [pd.w;2*pd.w(end)-pd.w(end-1)];
        end
        pd.maglabel = getString(message('signal:freqzplot:Zerophase'));
    end
    plotfresp_(ax,pd,'mag');
    
case 'phase',
    if nargin>3,
        pd.phaseh = phi;
        pd.phaseh = [pd.phaseh;inf*ones(1,size(pd.phaseh,2))];
        if length(pd.w)<size(pd.phaseh,1),
            pd.w = [pd.w;2*pd.w(end)-pd.w(end-1)];
        end
        if strcmpi(s.yphase, 'degrees'),
            pd.phaseh = pd.phaseh*180/pi;
        end
        if strcmpi(flag, 'zerocontphase'),
            pd.phaselabel = [getString(message('signal:freqzplot:ContinuousPhase')) ' (' s.yphase ')'];
        end
    end
    plotfresp_(ax,pd,'phase');
    
case 'both',
    if nargin>3,
        if size(phi,1) == 1
            phi = phi.';
        end
        pd.phaseh = phi;
        if ~s.fvflag
            pd.phaseh = [pd.phaseh;inf*ones(1,size(pd.phaseh,2))];
        end
        if strcmpi(s.yphase, 'degrees'),
            pd.phaseh = pd.phaseh*180/pi;
        end
    end
    % We plot the phase first to retain the functionality of freqz when hold is on
    ax(2) = subplot(212);
    plotfresp_(ax(2),pd,'phase');
    ax(1) = subplot(211);
    plotfresp_(ax(1),pd,'mag');
    
    if ishold,
        holdflag = 1;
    else
        holdflag = 0;
    end
    axes(ax(1)); % Bring the plot to the top & make subplot(211) current axis
    
    if ~holdflag,    % Reset the figure so that next plot does not subplot
        set(hfig,'nextplot','replace');       
    end      
end

set(ax,'xgrid','on','ygrid','on','xlim',pd.xlim); 
 
%-----------------------------------------------------------------------------------------
function s = parseOpts_(s,s_in)
%PARSEOPTS   Parse optional input params.
%   S is a structure which contains the fields described above plus:
%
%     S.fvflag - flag indicating if a freq. vector was given or nfft was given
%     S.ax     - handle to an axis where the plot will be generated on. (optional)

% Write out all string options
yunits_opts = {'db','linear','squared'};
plot_opts = {'both','mag','phase'};

if ischar(s_in),
	s = charcase_(s,s_in,yunits_opts,plot_opts);
	
elseif isstruct(s_in),
	
	s = structcase_(s,s_in,yunits_opts,plot_opts);
	
else
    error(message('signal:freqzplot:NeedPlotOpts'));
end

%-------------------------------------------------------------------------------
function s = charcase_(s,s_in,yunits_opts,plot_opts)
% This is for backwards compatibility, if a string with freq. units was
% specified as a third input arg. 
indx = find(strncmpi(s_in, yunits_opts, length(s_in)));
if ~isempty(indx),
	s.yunits = yunits_opts{indx};
else
	indx = find(strncmpi(s_in, plot_opts, length(s_in)));
	if ~isempty(indx),
		s.plot = plot_opts{indx};
	else
		% Assume these are user specified x units
		s.xunits = s_in;
	end
end

%-------------------------------------------------------------------------------
function s = structcase_(s,s_in,yunits_opts,plot_opts)

if isfield(s_in,'xunits'),
	s.xunits = s_in.xunits;
end

if isfield(s_in,'yunits'),
	s.yunits = s_in.yunits;
end

if isfield(s_in,'plot'),
	s.plot = s_in.plot;
end

if isfield(s_in,'fvflag'),
	s.fvflag = s_in.fvflag;
end

if isfield(s_in,'ax'),
	s.ax = s_in.ax;
end

if isfield(s_in,'yphase'),
    s.yphase = s_in.yphase;
end

% Check for validity of args
if ~ischar(s.xunits),
  error(message('signal:freqzplot:NeedStringFreqUnits'));
end

j = find(strncmpi(s.yunits, yunits_opts, length(s.yunits)));
if isempty(j),
  error(message('signal:freqzplot:InvalidMagnitudeUnits', 'db', 'linear', 'squared'));
end
s.yunits = yunits_opts{j};

k = find(strncmpi(s.plot, plot_opts, length(s.plot)));
if isempty(k),
  error(message('signal:freqzplot:InvalidPlotOpts', 'both', 'mag', 'phase'));
end
s.plot = plot_opts{k};


%-----------------------------------------------------------------------------------------
function plotfresp_(ax,pd,type)
switch type
case 'phase'
    data = pd.phaseh;
    lab  = pd.phaselabel;
case 'mag'
    data = pd.magh;
    lab  = pd.maglabel;
    if strcmpi(pd.maglabel, 'zero-phase'),
        lab = 'Amplitude';
    end
end
%axes(ax);
set(ax,'box','on')
line(pd.w,data,'parent',ax);
set(get(ax,'xlabel'),'string',pd.xlab);
set(get(ax,'ylabel'),'string',lab);


% [EOF] - freqzplot.m

function [pd,msg,msgobj] = genplotdata_(h,w,s)
%GENPLOTDATA Generate frequency response plotting data.
%
%   [PD,MSG] = GENPLOTDATA(H,W,S) generates the plotting data for 
%   the frequency response H computed at the frequencies specified in 
%   the vector W (in rad/sample).  S specifies additional plotting 
%   information that can be altered for different plotting options.  
%
%   PD is a structure which contains some of the following fields:
%   PD.W          - Frequency data
%   PD.XLAB       - Frequency axis (x-axis) label
%   PD.XLIM       - Frequency axis (x-axis) limits
%   PD.MAGH       - Magnitude data (possibly in dB)
%   PD.MAGLABEL   - Magnitude label
%   PD.PHASEH     - Unwrapped phase data (possibly in radians)
%   PD.PHASELABEL - Phase label

%   Author(s): R. Losada and P. Pacheco
%   Copyright 1988-2004 The MathWorks, Inc.

% If h is a vector, make it a column
if ndims(h) == 2 && min(size(h)) == 1
  h = h(:);
end

% Initialize outputs
 pd = [];
 msg = '';
 msgobj = [];
 
% Force w to be a column vector.
if ~any(size(w)==1),
   msgobj = message('signal:genplotdata:FreqInputMustBeVector','W');
   msg = getString(msgobj);
   return;   
end
pd.w = w(:);

changed_freq = 0; % This flag is used when s.plot is set to 'both'. If the freq vector,
                  % pd.w, is changed, the flag will be set to 1, this way we won't
                  % change pd.w again when generating the phase data.
                      
% Generate the appropriate data according to the desired plot type

% Cell array of the standard magnitude strings (used for the Ylabels)
magunitstrs = getmagunitstrs_;

if any(strncmp(s.plot,{'mag','both'}, length(s.plot))),
    % Generate the magnitude data
    pd.magh     = abs(h);
    pd.maglabel = magunitstrs{1};
    
    % Convert to Magnitude (dB)
    if strncmpi(s.yunits, 'db', length(s.yunits)),
        pd.magh     = convert2db_(pd.magh);
        pd.maglabel =  magunitstrs{2};
        
    % Convert to Magnitude Squared    
    elseif strncmpi(s.yunits, 'squared', length(s.yunits)),
        pd.magh     =  convert2sq_(pd.magh);
        pd.maglabel =  magunitstrs{3};
    end
    
    % Make sure you show the nyquist or 2*nyquist since freqz doesn't return this value
    if ~s.fvflag,
        pd.w = add_freq_point_(pd.w);
        changed_freq = 1;
        pd.magh = [pd.magh;inf*ones(1,size(pd.magh,2))]; 
    end
end

if any(strncmp(s.plot, {'phase','both'}, length(s.plot))),
    % Generate the phase data
    pd.phaseh = unwrap(angle(h));
    if strcmpi(s.yphase, 'degrees'),
        pd.phaseh = pd.phaseh*180/pi;
    end
    pd.phaselabel = ['Phase (' s.yphase ')'];
    
    % Make sure you show the nyquist or 2*nyquist since freqz doesn't return this value
    if ~s.fvflag,
        if ~changed_freq,
            pd.w = add_freq_point_(pd.w);    
        end
        pd.phaseh = [pd.phaseh;inf*ones(1,size(pd.phaseh,2))]; 
    end
end


% Generate the correct frequency units and label     

% Cell array of the standard frequency units strings (used for the Xlabels)
frequnitstrs = getfrequnitstrs_;

switch lower(s.xunits),
case 'rad/sample',
    pd.xlab = frequnitstrs{1};
    pd.w    = pd.w./pi; % Scale by pi in the plot
case 'hz',
    pd.xlab = frequnitstrs{2}; 
case 'khz',
    pd.xlab = frequnitstrs{3};
case 'mhz',
    pd.xlab = frequnitstrs{4}; 
case 'ghz',
    pd.xlab = frequnitstrs{5};
otherwise
    pd.xlab = s.xunits;
end

% Set x-axis range to be exactly the start and end points of w
pd.xlim = [pd.w(1) pd.w(end)]; 


%-----------------------------------------------------------------------------------------
function w_out = add_freq_point_(w)
%ADD_FREQ_POINT   adds an extra frequency point to the frequency vetor.
%   To be used when the frequency vector flag of FREQZ is not set to
%   make sure the entire Nyquist interval is shown in the plot even if
%   the Nyquist point is not included.
%
%   We made this a local function even though it is a one-liner because
%   it is called in two different places.

w_out = [w;2*w(end)-w(end-1)];

% [EOF]

function magunits = getmagunitstrs_
%GETMAGUNITSTRS Return a cell array of the standard Magnitude Units strings.

%   Author(s): P. Costa
%   Copyright 1988-2002 The MathWorks, Inc.

magunits = {'Magnitude',...
            'Magnitude (dB)',...
            'Magnitude Squared'};

% [EOF]

function HdB = convert2db_(H)
%CONVERT2DB Convert to decibels (dB).

%   Author(s): P. Costa
%   Copyright 1988-2002 The MathWorks, Inc.

ws = warning; % Cache warning state
warning off   % Avoid "Log of zero" warnings
HdB = db_(H);  % Call the Convert to decibels engine
warning(ws);  % Reset warning state

% [EOF]

function Y = db_(X,U,R)
%DB Convert to decibels.
%   DB(X) converts the elements of X to decibel units
%   across a 1 Ohm load.  The elements of X are assumed
%   to represent voltage measurements.
%
%   DB(X,U) indicates the units of the elements in X,
%   and may be 'power', 'voltage' or any portion of
%   either unit string.  If omitted, U='voltage'.
%
%   DB(X,R) indicates a measurement reference load of
%   R Ohms.  If omitted, R=1 Ohm.  Note that R is only
%   needed for the conversion of voltage measurements,
%   and is ignored if U is 'power'.
%
%   DB(X,U,R) specifies both a unit string and a
%   reference load.
%
%   EXAMPLES:
%       
%   % Example 1:Convert 0.1 volt to dB (1 Ohm ref.)
%               db(.1)           % -20 dB
%
%   % Example 2:Convert sqrt(.5)=0.7071 volts to dB (50 Ohm ref.)
%               db(sqrt(.5),50)  % -20 dB
%
%   % Example 3:Convert 1 mW to dB
%               db(1e-3,'power') % -30 dB
%
%   See also ABS, ANGLE.

%   Author(s): D. Orofino
%   Copyright 1988-2008 The MathWorks, Inc.

if nargin==1,
   % U='voltage'; R=1;
   X=abs(X).^2;
else
   if nargin==2,
      if ~ischar(U),
         R=U; U='voltage';
      else
         R=1;
      end
   end
   idx=find(strncmpi(U,{'power','voltage'}, length(U)));
   if length(idx)~=1,
      error(message('signal:db:InvalidEnum'));
   end
   if idx == 1,
      if any(X<0),
         error(message('signal:db:MustBePositive'));
      end
   else
      X=abs(X).^2./R;
   end
end

% We want to guarantee that the result is an integer
% if X is a negative power of 10.  To do so, we force
% some rounding of precision by adding 300-300.

Y = (10.*log10(X)+300)-300;

% [EOF] db.m

function frequnits = getfrequnitstrs_(menuflag)
%GETFREQUNITSTRS Return a cell array of frequency units strings.
%
%   STRS = GETFREQUNITS returns a cell array of standard frequency units 
%   strings.

%   STRS = GETFREQUNITS(MENUFLAG) returns a cell array of frequency units
%   with the "Normalized Frequency" string for use in a uimenu.

%   Author(s): P. Costa
%   Copyright 1988-2002 The MathWorks, Inc.

frequnits = {    'Normalized Frequency  (\times\pi rad/sample)'    'Frequency (Hz)'    'Frequency (kHz)'    'Frequency (MHz)'    'Frequency (GHz)'    'Frequency (THz)'    'Frequency (PHz)'    'Frequency (EHz)'  'Frequency (ZHz)'    'Frequency (YHz)'    'Frequency (yHz)'    'Frequency (zHz)'    'Frequency (aHz)'    'Frequency (fHz)'    'Frequency (pHz)'    'Frequency (nHz)' 'Frequency (\muHz)'    'Frequency (?Hz)'    'Frequency (mHz)'};

% Return the proper version of the Normalized Frequency string
% for the X-axis label or menu item.
if nargin == 1,
    frequnits{1} = 'Normalized Frequency';
end

% [EOF]

function [x,msg] = datawrap_(x,nfft)
%DATAWRAP Wrap input data modulo nfft.
%   DATAWRAP(X,NFFT) wraps the vector X modulo NFFT.
%   
%   The operation consists of dividing the vector X into segments each of
%   length NFFT (possibly padding with zeros the last segment).  Subsequently,
%   the length NFFT segments are added together to obtain a wrapped version of X.

%   Author(s): R. Losada 
%   Copyright 1988-2004 The MathWorks, Inc.

nx = size(x, 2);
msg = '';
if all(size(x)>1),
   error(message('signal:datawrap:InvalidInput'));
end

% Reshape into multiple columns (data segments) of length nfft.
% If insufficient data points are available, zeros are appended.
% Sum across the columns (data segments).
x = sum(buffer(x,nfft),2);
% Reshape vector as necessary:
if (nx~=1), x=x.'; end

% [EOF] datawrap.m

function Hsq = convert2sq_(H)
%CONVERT2SQ Convert to square.

%   Author(s): P. Costa
%   Copyright 1988-2002 The MathWorks, Inc.

Hsq = H.^2;

% [EOF]
