function [num, den, z, p] = cheby2_(n, r, Wn, varargin)
%CHEBY2 Chebyshev Type II digital and analog filter design.
%   [B,A] = CHEBY2(N,R,Wst) designs an Nth order lowpass digital Chebyshev
%   filter with the stopband ripple R decibels down and stopband-edge
%   frequency Wst.  CHEBY2 returns the filter coefficients in length N+1
%   vectors B (numerator) and A (denominator). The stopband-edge frequency
%   Wst must be 0.0 < Wst < 1.0, with 1.0 corresponding to half the sample
%   rate.  Use R = 20 as a starting point, if you are unsure about choosing
%   R.
%
%   If Wst is a two-element vector, Wst = [W1 W2], CHEBY2 returns an order
%   2N bandpass filter with passband  W1 < W < W2. [B,A] =
%   CHEBY2(N,R,Wst,'high') designs a highpass filter. [B,A] =
%   CHEBY2(N,R,Wst,'low') designs a lowpass filter. [B,A] =
%   CHEBY2(N,R,Wst,'stop') is a bandstop filter if Wst = [W1 W2].
%
%   When used with three left-hand arguments, as in [Z,P,K] = CHEBY2(...),
%   the zeros and poles are returned in length N column vectors Z and P,
%   and the gain in scalar K.
%
%   When used with four left-hand arguments, as in [A,B,C,D] = CHEBY2(...),
%   state-space matrices are returned.
%
%   CHEBY2(N,R,Wst,'s'), CHEBY2(N,R,Wst,'high','s') and
%   CHEBY2(N,R,Wst,'stop','s') design analog Chebyshev Type II filters. In
%   this case, Wst is in [rad/s] and it can be greater than 1.0.
%
%   % Example 1:
%   %   For data sampled at 1000 Hz, design a ninth-order lowpass
%   %   Chebyshev Type II filter with stopband attenuation 40 dB down from
%   %   the passband and a stopband edge frequency of 300Hz.
%
%   Wn = 300/500;               % Normalized stopband edge frequency
%   [z,p,k] = cheby2(9,40,Wn);
%   [sos] = zp2sos(z,p,k);      % Convert to SOS form
%   h = fvtool(sos)             % Plot magnitude response
%
%   % Example 2:
%   %   Design a 6th-order Chebyshev Type II band-pass filter which passes
%   %   frequencies between 0.2 and 0.5 and with stopband attenuation 80 dB
%   %   down from the passband.
%
%   [b,a]=cheby2(6,80,[.2,.5]);     % Bandpass digital filter design
%   h = fvtool(b,a);                % Visualize filter
%
%   See also CHEB2ORD, CHEBY1, BUTTER, ELLIP, FREQZ, FILTER, DESIGNFILT.

%   Author(s): J.N. Little, 1-14-87
%   	   J.N. Little, 1-13-88, revised
%   	   L. Shure, 4-29-88, revised
%   	   T. Krauss, 3-25-93, revised
%   Copyright 1988-2013 The MathWorks, Inc.

%   References:
%     [1] T. W. Parks and C. S. Burrus, Digital Filter Design,
%         John Wiley & Sons, 1987, chapter 7, section 7.3.3.

% Cast to enforce precision rules


[btype,analog,errStr,msgobj] = iirchk(Wn,varargin{:});
if ~isempty(errStr), error(msgobj); end

if n>500
    error(message('signal:cheby2:InvalidRange'))
end

% step 1: get analog, pre-warped frequencies
if ~analog,
    fs = 2;
    u = 2*fs*tan(pi*Wn/fs);
else
    u = Wn;
end

% step 2: convert to low-pass prototype estimate
if btype == 1	% lowpass
    Wn = u;
elseif btype == 2	% bandpass
    Bw = u(2) - u(1);
    Wn = sqrt(u(1)*u(2));	% center frequency
elseif btype == 3	% highpass
    Wn = u;
elseif btype == 4	% bandstop
    Bw = u(2) - u(1);
    Wn = sqrt(u(1)*u(2));	% center frequency
end

% step 3: Get N-th order Chebyshev type-II lowpass analog prototype
[z,p,k] = cheb2ap(n, r);

% Transform to state-space
[a,b,c,d] = zp2ss(z,p,k);

% step 4: Transform to lowpass, bandpass, highpass, or bandstop of desired Wn
if btype == 1		% Lowpass
    [a,b,c,d] = lp2lp(a,b,c,d,Wn);
    
elseif btype == 2	% Bandpass
    [a,b,c,d] = lp2bp(a,b,c,d,Wn,Bw);
    
elseif btype == 3	% Highpass
    [a,b,c,d] = lp2hp(a,b,c,d, Wn);
    
elseif btype == 4	% Bandstop
    [a,b,c,d] = lp2bs(a,b,c,d,Wn,Bw);
end

% step5: Use Bilinear transformation to find discrete equivalent:
if ~analog,
    [a,b,c,d] = bilinear(a,b,c,d,fs);
end

if nargout == 4
    num = a;
    den = b;
    z = c;
    p = d;
else	% nargout <= 3
    % Transform to zero-pole-gain and polynomial forms:
    if nargout == 3
        [z,p,k] = ss2zp(a,b,c,d,1);
        num = z;
        den = p;
        z = k;
    else % nargout <= 2
        den = poly(a);
        if analog
            zeroLimitFlag = true;
        else
            zeroLimitFlag = false;
        end
        zinf = ltipack.getTolerance('infzero',zeroLimitFlag);
        [z,k] = ltipack.sszero(a,b,c,d,[],zinf);
        num = k * poly(z);
        num = [zeros(1,length(den)-length(num)) num];
    end
end


function [btype,analog,errStr,msgobj] = iirchk(Wn,varargin)
%IIRCHK  Parameter checking for BUTTER, CHEBY1, CHEBY2, and ELLIP.
%   [btype,analog,errStr] = iirchk(Wn,varargin) returns the 
%   filter type btype (1=lowpass, 2=bandpss, 3=highpass, 4=bandstop)
%   and analog flag analog (0=digital, 1=analog) given the edge
%   frequency Wn (either a one or two element vector) and the
%   optional arguments in varargin.  The variable arguments are 
%   either empty, a one element cell, or a two element cell.
%
%   errStr is empty if no errors are detected; otherwise it contains
%   the error message.  If errStr is not empty, btype and analog
%   are invalid.

%   Copyright 1988-2002 The MathWorks, Inc.

errStr = '';
msgobj = [];

% Define defaults:
analog = 0; % 0=digital, 1=analog
btype = 1;  % 1=lowpass, 2=bandpss, 3=highpass, 4=bandstop

if length(Wn)==1
    btype = 1;  
elseif length(Wn)==2
    btype = 2;
else
    msgobj = message('signal:iirchk:MustBeOneOrTwoElementVector','Wn');
    errStr = getString(msgobj);
    return
end

if length(varargin)>2
    msgobj = message('signal:iirchk:TooManyInputArguments');
    errStr = getString(msgobj);
    return
end

% Interpret and strip off trailing 's' or 'z' argument:
if length(varargin)>0 
    switch lower(varargin{end})
    case 's'
        analog = 1;
        varargin(end) = [];
    case 'z'
        analog = 0;
        varargin(end) = [];
    otherwise
        if length(varargin) > 1
            msgobj = message('signal:iirchk:BadAnalogFlag','z','s');
            errStr = getString(msgobj);
            return
        end
    end
end

% Check for correct Wn limits
if ~analog
   if any(Wn<=0) | any(Wn>=1)
      msgobj = message('signal:iirchk:FreqsMustBeWithinUnitInterval');
      errStr = getString(msgobj);
      return
   end
else
   if any(Wn<=0)
      msgobj = message('signal:iirchk:FreqsMustBePositive');
      errStr = getString(msgobj);
      return
   end
end

% At this point, varargin will either be empty, or contain a single
% band type flag.

if length(varargin)==1   % Interpret filter type argument:
    switch lower(varargin{1})
    case 'low'
        btype = 1;
    case 'bandpass'
        btype = 2;
    case 'high'
        btype = 3;
    case 'stop'
        btype = 4;
    otherwise
        if nargin == 2
            msgobj = message('signal:iirchk:BadOptionString', ...
              'high','stop','low','bandpass','z','s');
            errStr = getString(msgobj);
        else  % nargin == 3
            msgobj = message('signal:iirchk:BadFilterType', ...
              'high','stop','low','bandpass');
            errStr = getString(msgobj);
        end
        return
    end
    switch btype
    case 1
        if length(Wn)~=1
            msgobj = message('signal:iirchk:BadOptionLength','low','Wn',1);
            errStr = getString(msgobj);
            return
        end
    case 2
        if length(Wn)~=2
            msgobj = message('signal:iirchk:BadOptionLength','bandpass','Wn',2);
            errStr = getString(msgobj);
            return
        end
    case 3
        if length(Wn)~=1
            msgobj = message('signal:iirchk:BadOptionLength','high','Wn',1);
            errStr = getString(msgobj);
            return
        end
    case 4
        if length(Wn)~=2
            msgobj = message('signal:iirchk:BadOptionLength','stop','Wn',2);
            errStr = getString(msgobj);
            return
        end
    end
end
 

function [z,p,k] = cheb2ap(n, rs)
%CHEB2AP Chebyshev Type II analog lowpass filter prototype.
%   [Z,P,K] = CHEB2AP(N,Rs) returns the zeros, poles, and gain
%   of an N-th order normalized analog prototype Chebyshev Type II
%   lowpass filter with Rs decibels of ripple in the stopband.
%   Chebyshev Type II filters are maximally flat in the passband.
%
%   % Example:
%   %   Design a 6-th order Chebyshev Type II analog low pass filter with
%   %   70dB of ripple in the stopband and display its frequency response.
%
%   [z,p,k]=cheb2ap(6,70);      % Lowpass filter prototype
%   [num,den]=zp2tf(z,p,k);     % Convert to transfer function form
%   freqs(num,den)              % Frequency response of analog filter  
%
%   See also CHEBY2, CHEB2ORD, BUTTAP, CHEB1AP, ELLIPAP.

%   Copyright 1988-2013 The MathWorks, Inc.

validateattributes(n,{'numeric'},{'scalar','integer','positive'},'cheb2ap','N');
validateattributes(rs,{'numeric'},{'scalar','nonnegative'},'cheb2ap','Rs');

% Cast to enforce precision rules
n = double(n);
rs = double(rs);

delta = 1/sqrt(10^(.1*rs)-1);
mu = asinh(1/delta)/n;
if (rem(n,2))
	m = n - 1;
	z = cos([1:2:n-2 n+2:2:2*n-1]*pi/(2*n))';
else
	m = n;
	z = cos((1:2:2*n-1)*pi/(2*n))';
end
z = (z - flipud(z))./2;
z = 1i./z;
% Organize zeros in complex pairs:
i = [1:m/2; m:-1:m/2+1];
z = z(i(:));

p = exp(1i*(pi*(1:2:2*n-1)/(2*n) + pi/2)).';
realp = real(p); realp = (realp + flipud(realp))./2;
imagp = imag(p); imagp = (imagp - flipud(imagp))./2;
p = complex(sinh(mu)*realp, cosh(mu)*imagp);
p = 1 ./ p;
k = real(prod(-p)/prod(-z));



function [at,bt,ct,dt] = lp2lp(a,b,c,d,wo)
%LP2LP Lowpass to lowpass analog filter transformation.
%   [NUMT,DENT] = LP2LP(NUM,DEN,Wo) transforms the lowpass filter
%   prototype NUM(s)/DEN(s) with unity cutoff frequency of 1 rad/sec
%   to a lowpass filter with cutoff frequency Wo (rad/sec).
%   [AT,BT,CT,DT] = LP2LP(A,B,C,D,Wo) does the same when the
%   filter is described in state-space form.
%
%   % Example:
%   %   Design a Elliptic analog lowpass filter with 5dB of ripple in the
%   %   passband and a stopband 90 decibels down. Change the cutoff
%   %   frequency of this lowpass filter to 24Hz.
%
%   Wo= 24;                         % Cutoff frequency
%   [z,p,k]=ellipap(6,5,90);        % Lowpass filter prototype
%   [b,a]=zp2tf(z,p,k);             % Specify filter in polynomial form
%   [num,den]=lp2lp(b,a,Wo);        % Change cutoff frequency
%   freqs(num,den)                  % Frequency response of analog filter
%
%   See also BILINEAR, IMPINVAR, LP2BP, LP2BS and LP2HP

%   Author(s): J.N. Little and G.F. Franklin, 8-4-87
%   Copyright 1988-2013 The MathWorks, Inc.

if nargin == 3		% Transfer function case
    % handle column vector inputs: convert to rows
    if size(a,2) == 1
        a = a(:).';
    end
    if size(b,2) == 1
        b = b(:).';
    end
    % Cast to enforce precision rules

   
    % Transform to state-space
    [a,b,c,d] = tf2ss(a,b);
elseif (nargin == 5)
  % Cast to enforce precision rules
 
else
  error(message('signal:lp2lp:MustHaveNInputs'));
end
error(abcdchk(a,b,c,d));

% Transform lowpass to lowpass
at = wo*a;
bt = wo*b;
ct = c;
dt = d;

if nargin == 3		% Transfer function case
    % Transform back to transfer function
    zinf = ltipack.getTolerance('infzero',true);
    [z,k] = ltipack.sszero(at,bt,ct,dt,[],zinf);
    num = k * poly(z);
    den = poly(at);
    at = num;
    bt = den;
end

function [zd, pd, kd, dd] = bilinear(z, p, k, fs, fp, fp1)
%BILINEAR Bilinear transformation with optional frequency prewarping.
%   [Zd,Pd,Kd] = BILINEAR(Z,P,K,Fs) converts the s-domain transfer
%   function specified by Z, P, and K to a z-transform discrete
%   equivalent obtained from the bilinear transformation:
%
%      H(z) = H(s) |
%                  | s = 2*Fs*(z-1)/(z+1)
%
%   where column vectors Z and P specify the zeros and poles, scalar
%   K specifies the gain, and Fs is the sample frequency in Hz.
%
%   [NUMd,DENd] = BILINEAR(NUM,DEN,Fs), where NUM and DEN are
%   row vectors containing numerator and denominator transfer
%   function coefficients, NUM(s)/DEN(s), in descending powers of
%   s, transforms to z-transform coefficients NUMd(z)/DENd(z).
%
%   [Ad,Bd,Cd,Dd] = BILINEAR(A,B,C,D,Fs) is a state-space version.
%
%   Each of the above three forms of BILINEAR accepts an optional
%   additional input argument that specifies prewarping.
%
%   For example, [Zd,Pd,Kd] = BILINEAR(Z,P,K,Fs,Fp) applies prewarping
%   before the bilinear transformation so that the frequency responses
%   before and after mapping match exactly at frequency point Fp
%   (match point Fp is specified in Hz).
%
%   % Example:
%   %   Design a 6-th order Elliptic analog low pass filter and transform
%   %   it to a Discrete-time representation.
%
%   Fs =0.5;                            % Sampling Frequency
%   [z,p,k]=ellipap(6,5,90);            % Lowpass filter prototype
%   [num,den]=zp2tf(z,p,k);             % Convert to transfer function form
%   [numd,dend]=bilinear(num,den,Fs);   % Analog to Digital conversion
%   fvtool(numd,dend)                   % Visualize the filter
%
%   See also IMPINVAR.

%   Author(s): J.N. Little, 4-28-87
%   	   J.N. Little, 5-5-87, revised
%   Copyright 1988-2006 The MathWorks, Inc.

%   Gene Franklin, Stanford Univ., motivated the state-space
%   approach to the bilinear transformation.

[mn,nn] = size(z);
[md,nd] = size(p);
if (nd == 1 && nn < 2) && nargout ~= 4	% In zero-pole-gain form
    if mn > md
        error(message('signal:bilinear:InvalidRange'))
    end
    if nargin == 5
      % Cast to enforce Precision Rules
      % Prewarp
      fp = 2*pi*fp;
      fs = fp/tan(fp/fs/2);
    else
      % Cast to enforce Precision Rules
      fs = 2*fs;
    end
    % Cast to enforce Precision Rules
    z = z(isfinite(z));	 % Strip infinities from zeros
    pd = (1+p/fs)./(1-p/fs); % Do bilinear transformation
    zd = (1+z/fs)./(1-z/fs);
    % real(kd) or just kd?
    kd = (k*prod(fs-z)./prod(fs-p));
    zd = [zd;-ones(length(pd)-length(zd),1)];  % Add extra zeros at -1
    
elseif (md == 1 && mn == 1) || nargout == 4 %
    if nargout == 4		% State-space case
        % Cast to enforce Precision Rules
        a = z;
        b = p;
        c = k;
        d = fs; 
        fs = fp;
        error(abcdchk(a,b,c,d));
        if nargin == 6			% Prewarp
          % Cast to enforce Precision Rules
          fp = fp1;
          fp = 2*pi*fp;
          fs = fp/tan(fp/fs/2)/2;
        end
    else			% Transfer function case
        if nn > nd
            error(message('signal:bilinear:InvalidRange'))
        end
        num = z; den = p;		% Decode arguments
        if nargin == 4			% Prewarp
            % Cast to enforce Precision Rules
            fp = fs;
            fs = k;
            fp = 2*pi*fp;
            fs = fp/tan(fp/fs/2)/2;
            
        else
            % Cast to enforce Precision Rules
            fs = k;
        end
        
        % Put num(s)/den(s) in state-space canonical form.
        [a,b,c,d] = tf2ss(num,den);
    end
    % Now do state-space version of bilinear transformation:
    t = 1/fs;
    r = sqrt(t);
    t1 = eye(size(a)) + a*t/2;
    t2 = eye(size(a)) - a*t/2;
    ad = t2\t1;
    bd = t/r*(t2\b);
    cd = r*c/t2;
    dd = c/t2*b*t/2 + d;
    if nargout == 4
        zd = ad; pd = bd; kd = cd;
    else
        % Convert back to transfer function form:
        p = poly(ad);
        zd = poly(ad-bd*cd)+(dd-1)*p;
        pd = p;
    end
else
    error(message('signal:bilinear:SignalErr'))
end

function [at,bt,ct,dt] = lp2bp(a,b,c,d,wo,bw)
%LP2BP Lowpass to bandpass analog filter transformation.
%   [NUMT,DENT] = LP2BP(NUM,DEN,Wo,Bw) transforms the lowpass filter
%   prototype NUM(s)/DEN(s) with unity cutoff frequency to a
%   bandpass filter with center frequency Wo and bandwidth Bw.
%   [AT,BT,CT,DT] = LP2BP(A,B,C,D,Wo,Bw) does the same when the
%   filter is described in state-space form.
%
%   % Example:
%   %   Design a Elliptic analog lowpass filter with 5dB of ripple in the
%   %   passband and a stopband 90 decibels down. Transform this filter to
%   %   a bandpass filter with center frequency 24Hz and Bandwidth of 10Hz.
%
%   Wo= 24; Bw=10                   % Define Center frequency and Bandwidth
%   [z,p,k]=ellipap(6,5,90);        % Lowpass filter prototype
%   [b,a]=zp2tf(z,p,k);             % Specify filter in polynomial form
%   [num,den]=lp2bp(b,a,Wo,Bw);     % Convert LPF to BPF
%   freqs(num,den)                  % Frequency response of analog filter
%
%   See also BILINEAR, IMPINVAR, LP2LP, LP2BS and LP2HP

%   Author(s): J.N. Little and G.F. Franklin, 8-4-87
%   Copyright 1988-2013 The MathWorks, Inc.


if nargin == 4		% Transfer function case
    % handle column vector inputs: convert to rows
    if size(a,2) == 1
        a = a(:).';
    end
    if size(b,2) == 1
        b = b(:).';
    end
    
    % Cast to enforce precision rules
%     wo = signal.internal.sigcasttofloat(c,'double','lp2bp','Wo',...
%       'allownumeric');
%     bw = signal.internal.sigcasttofloat(d,'double','lp2bp','Bw',...
%       'allownumeric');
%     if any([signal.internal.sigcheckfloattype(b,'single','lp2bp','DEN')...
%         signal.internal.sigcheckfloattype(a,'single','lp2bp','NUM')])
%       b = single(b);
%       a = single(a);
%     end
    % Transform to state-space
    [a,b,c,d] = tf2ss(a,b);

elseif (nargin == 6)
  % Cast to enforce precision rules
%   if any([signal.internal.sigcheckfloattype(a,'single','lp2bp','A')...
%       signal.internal.sigcheckfloattype(b,'single','lp2bp','B')...
%       signal.internal.sigcheckfloattype(c,'single','lp2bp','C')...
%       signal.internal.sigcheckfloattype(d,'single','lp2bp','D')])
%     a = single(a);
%     b = single(b);   
%     c = single(c);
%     d = single(d);
%   end
%   wo = signal.internal.sigcasttofloat(wo,'double','lp2bp','Wo',...
%     'allownumeric');
%   bw = signal.internal.sigcasttofloat(bw,'double','lp2bp','Bw',...
%     'allownumeric');
else
  error(message('signal:lp2bp:MustHaveNInputs'));
end

error(abcdchk(a,b,c,d));

nb = size(b, 2);
[mc,ma] = size(c);

% Transform lowpass to bandpass
q = wo/bw;
at = wo*[a/q eye(ma); -eye(ma) zeros(ma)];
bt = wo*[b/q; zeros(ma,nb)];
ct = [c zeros(mc,ma)];
dt = d;

if nargin == 4		% Transfer function case
    % Transform back to transfer function
    zinf = ltipack.getTolerance('infzero',true);
    [z,k] = ltipack.sszero(at,bt,ct,dt,[],zinf);
    num = k * poly(z);
    den = poly(at);
    at = num;
    bt = den;
end
