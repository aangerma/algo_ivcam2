function varargout = phasedelay(b,varargin)
%PHASEDELAY Phase delay of digital filter
%   [PHI,W] = PHASEDELAY(B,A,N) returns the N-point phase delay response
%   vector PHI (in samples) and the N-point frequency vector W (in
%   radians/sample) of the filter:
%
%               jw               -jw              -jmw
%        jw  B(e)    b(1) + b(2)e + .... + b(m+1)e
%     H(e) = ---- = ------------------------------------
%               jw               -jw              -jnw
%            A(e)    a(1) + a(2)e + .... + a(n+1)e
%
%   given numerator and denominator coefficients in vectors B and A.
%
%   [PHI,W] = PHASEDELAY(SOS,N) computes the phase delay response of the
%   filter specified using the second order sections matrix SOS. SOS is a
%   Kx6 matrix, where the number of sections, K, must be greater than or
%   equal to 2. Each row of SOS corresponds to the coefficients of a second
%   order filter. From the transfer function displayed above, the ith row
%   of the SOS matrix corresponds to [bi(1) bi(2) bi(3) ai(1) ai(2) ai(3)].
%
%   [PHI,W] = PHASEDELAY(D,N) computes the phase delay response of the
%   digital filter, D. You design a digital filter, D, by calling the 
%   <a href="matlab:help designfilt">designfilt</a> function.
%
%   In all cases, the phase response is evaluated at N points equally
%   spaced around the upper half of the unit circle. If N isn't specified,
%   it defaults to 512.
%
%   [PHI,W] = PHASEDELAY(...,N,'whole') uses N points around the whole unit
%   circle.
%
%   [PHI,F] = PHASEDELAY(...,N,Fs) and [PHI,F] =PHASEDELAY(...,N,'whole',Fs)
%   return a frequency vector, F, in Hz when you specify the sample rate Fs
%   in Hz.
%
%   PHI = PHASEDELAY(...,W) and PHI = PHASEDELAY(..,F,Fs) return the phase
%   delay response evaluated at the points specified in frequency vectors W
%   (in radians/sample), or F (in Hz).
%
%   PHASEDELAY(...) with no output arguments plots the phase delay response
%   of the filter in the current figure window.
%
%   % Example 1:
%   %   Design a lowpass FIR filter with normalized cut-off frequency at
%   %   0.3 and determine its phase delay.
%
%   b=fircls1(54,0.3,0.02,0.008);
%   phasedelay(b)
%
%   % Example 2:
%   %   Design a 5th order lowpass elliptic IIR filter and determine its
%   %   phase delay.
%
%   [b,a] = ellip(5,0.5,20,0.4);
%   phasedelay(b,a)
%
%   % Example 3:
%   %   Design a Butterworth highpass IIR filter, represent its coefficients
%   %   using second order sections, and display its phase delay response.
%
%   [z,p,k] = butter(6,0.7,'high');
%   SOS = zp2sos(z,p,k);
%   phasedelay(SOS)
%
%   % Example 4:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 8, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Sample rate is 200 KHz. Visualize the phase delay response 
%   %   using 2048 frequency points.
%  
%   D = designfilt('highpassiir', 'FilterOrder', 8, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   phasedelay(D,2048)
%
%   See also FREQZ, PHASEZ, ZEROPHASE, GRPDELAY and FVTOOL.

%   Copyright 1988-2013 The MathWorks, Inc.

narginchk(1,5);

isTF = true; % True if dealing with a transfer function

if all(size(b)>[1 1])
    % Input is a matrix, check if it is a valid SOS matrix
    if size(b,2) ~= 6
        error(message('signal:signalanalysisbase:invalidinputsosmatrix'));
    end
    % Checks if SOS is a valid numeric data input
    
    isTF = false; % SOS instead of transfer function
end

if isTF
    if isempty(varargin)
        a = 1; % Assume FIR
    else
        a = varargin{1};
        varargin(1) = [];
    end
    
    % Checks if B and A are valid numeric data inputs

    if ~isreal(b) || ~isreal(a),
        [phi,w,s] = phasez(b,a,varargin{:});
    else
        % Use the continuous phase
        [~,w,phi,s] = zerophase(b,a,varargin{:});
    end
else
    [~,w, phi, s] = zerophase(b, varargin{:});
end

% Note that phi and w span between [0, pi)/[0, fs/2)
phd = dividenowarn(-phi,w);

% Cast to enforce precision rules
% Only cast if output is requested, otherwise, plot using double precision
% frequency vector. 
if nargout > 1 && isa(phd,'single')
  w = single(w);
end

% Parse outputs
switch nargout
    case 0
        % Plot when no output arguments are given
        phasedelayplot(phd,w,s);
    case 1
        varargout = {phd};
    case 2
        varargout = {phd,w};
    case 3
        varargout = {phd,w,s};
end


%-------------------------------------------------------------------------------
function phasedelayplot(phd,w,s)

% Cell array of the standard frequency units strings (used for the Xlabels)
frequnitstrs = getfrequnitstrs;
if isempty(s.Fs),
    xlab = frequnitstrs{1};
    w    = w./pi; % Scale by pi in the plot
    ylab = 'Phase delay (samples)';
else
    xlab = frequnitstrs{2};
    ylab = 'Phase delay (rad/Hz)';
end

plot(w,phd);
xlabel(xlab);
ylabel(ylab);
grid on;

% [EOF]

function varargout = zerophase(b,varargin)
%ZEROPHASE Zero-phase response of real digital filter
%   [Hr,W] = ZEROPHASE(B,A) returns the zero-phase response Hr, and the
%   frequency vector W (in rad/sample) at which Hr is computed, for the
%   filter:
%
%               jw               -jw              -jmw
%        jw  B(e)    b(1) + b(2)e + .... + b(m+1)e
%     H(e) = ---- = ------------------------------------
%               jw               -jw              -jnw
%            A(e)    a(1) + a(2)e + .... + a(n+1)e
%
%   given numerator and denominator coefficients in vectors B and A.
%
%   [Hr,W] = ZEROPHASE(SOS) computes the zero-phase response of the filter
%   specified using the second order sections matrix SOS. SOS is a Kx6
%   matrix, where the number of sections, K, must be greater than or equal
%   to 2. Each row of SOS corresponds to the coefficients of a second order
%   filter. From the transfer function displayed above, the ith row of the
%   SOS matrix corresponds to [bi(1) bi(2) bi(3) ai(1) ai(2) ai(3)].
%
%   [Hr,W] = ZEROPHASE(D) computes the zero-phase response of the digital
%   filter, D. You design a digital filter, D, by calling the <a href="matlab:help designfilt">designfilt</a>
%   function.
%
%   In all cases, the zero-phase response is evaluated at 512 equally
%   spaced points on the upper half of the unit circle.
%
%   The zero-phase response, Hr(w), is related to the frequency response,
%   H(w) by:
%                                       jPhiz(w)
%                          H(w) = Hr(w)e
%
%   Note that the zero-phase response is always real, but it is not
%   equivalent to the magnitude response. In particular, the former can be
%   negative whereas the latter cannot.
%
%   [Hr,W] = ZEROPHASE(..., NFFT) uses NFFT frequency points on the upper
%   half of the unit circle when computing the zero-phase response.
%
%   [Hr,W] = ZEROPHASE(...,NFFT,'whole') uses NFFT frequency points around
%   the whole unit circle.
%
%   [Hr,F] = ZEROPHASE(...,Fs) and [Hr,F] = ZEROPHASE(...,'whole',Fs) use
%   the sampling frequency Fs, in Hz, to determine the frequency vector F
%   (in Hz) at which Hr is computed.
%
%   Hr = ZEROPHASE(...,W) and Hr = ZEROPHASE(..,F,Fs) return the zero phase
%   response at the points specified in frequency vectors W (in
%   radians/sample), or F (in Hz).
%
%   [Hr,W,Phi] = ZEROPHASE(...) returns the continuous phase Phi. Note that
%   this quantity is not equivalent to the phase response of the filter
%   when the zero-phase response is negative.
%
%   ZEROPHASE(...) with no output arguments, plots the zero-phase response
%   versus frequency.
%
%   % Example 1:
%   %   Design a lowpass FIR filter with normalized cut-off frequency at
%   %   0.3 and determine its zero-phase response.
%
%   b=fircls1(54,0.3,0.02,0.008);
%   zerophase(b)
%
%   % Example 2:
%   %   Design a 5th order lowpass elliptic IIR filter and determine its
%   %   zero-phase response.
%
%   [b,a] = ellip(5,0.5,20,0.4);
%   zerophase(b,a,512,'whole')
%
%   % Example 3:
%   %   Design a Butterworth highpass IIR filter, represent its coefficients
%   %   using second order sections, and display its zero-phase response.
%
%   [z,p,k] = butter(6,0.7,'high');
%   SOS = zp2sos(z,p,k);
%   zerophase(SOS)
%
%   % Example 4:
%   %   Use the designfilt function to design a highpass IIR digital filter 
%   %   with order 8, passband frequency of 75 KHz, and a passband ripple 
%   %   of 0.2 dB. Sample rate is 200 KHz. Visualize the zero-phase response 
%   %   using 2048 frequency points.
%  
%   D = designfilt('highpassiir', 'FilterOrder', 8, ...
%            'PassbandFrequency', 75e3, 'PassbandRipple', 0.2,...
%            'SampleRate', 200e3);
%
%   zerophase(D,2048)
%
%   See also FREQZ, INVFREQZ, PHASEZ, FREQS, PHASEDELAY, GRPDELAY and FVTOOL.

%   Copyright 1988-2013 The MathWorks, Inc.

% Error checking
narginchk(1,5);
a = 1;

isTF = true; % True if dealing with a transfer function

if all(size(b)>[1 1])
    % Input is a matrix, check if it is a valid SOS matrix
    if size(b,2) ~= 6
        error(message('signal:signalanalysisbase:invalidinputsosmatrix'));
    end
    % Checks if SOS is a valid numeric data input
    isTF = false; % SOS instead of transfer function
end

if isTF && ~isempty(varargin)
    a = varargin{1};
    if all(size(a)>[1 1])
        error(message('signal:signalanalysisbase:inputnotsupported'));
    end
    varargin(1) = [];
    % Checks if B and A are valid numeric data inputs
end

if ~isreal(b) || ~isreal(a),
    error(message('signal:zerophase:NotSupported'));
end

if isTF
    errStr = 'iirfilter';
    % Linear-phase FIR filter
    if length(a)==1,
        [Hz,wz,phiz,s,options,errStr] = exactzerophase(b/a, varargin{:});
    end
    
    if ~isempty(errStr),
        
        % Parse inputs
        [n_or_w, options, do_transpose1] = extract_norw(varargin{:});
        
        % Add f=0 if not included in the frequency factor
        if length(n_or_w)>1,
            addpoint = 0;
            idx = find(n_or_w>=0, 1);
            if isempty(idx),
                % Only negative frequencies
                addpoint = 1;
                n_or_w = [n_or_w,0];
            else
                idx = find(n_or_w<=0, 1);
                if isempty(idx),
                    % Only positive frequencies
                    addpoint = -1;
                    n_or_w = [0,n_or_w];
                end
            end
        end
        
        % Define the new N-point frequency vector where the frequency response is evaluated
        [upn_or_w, upfactor, iswholerange, do_transpose2] = getinterpfrequencies(n_or_w, varargin{:});
        
        % Compute the phase response (phasez) on the desired range
        phi = compute_phase(b, a, upn_or_w, options);
        
        % Estimate the sign of H on the desired range
        [Hsign, isfirstsegmentpositive,periodicity,flip] = estimateHsign(b, ...
            a, phi, iswholerange, upn_or_w);
        
        % Compute the frequency response (freqz)
        [h, wz, s, options] = compute_fresp(b, a, upn_or_w, options);
        
        % Zero-phase response
        if length(n_or_w)>1,
            if addpoint==1,
                isoriginpositive= (Hsign(end) == 1);
            elseif addpoint==-1,
                isoriginpositive= (Hsign(1) == 1);
            else
                idx = find(upn_or_w>=0);
                isoriginpositive = (Hsign(idx(1)) == 1);
            end
            % Vector specified (not nfft)
            if isfirstsegmentpositive*isoriginpositive~=1,
                Hsign = -Hsign;
            end
        end
        Hz = Hsign.*abs(h(:));
        
        % Continuous phase
        phiz = compute_continuousphase(Hsign, phi, isfirstsegmentpositive);
        
        % Downsample to retrieve the number of points specified by the user
        A = downsample([Hz(:), phiz(:), wz(:)], upfactor);
        Hz   = A(:,1);
        phiz = A(:,2);
        wz   = A(:,3);
        
        if xor(do_transpose1,do_transpose2),
            Hz = Hz.';
            phiz = phiz.';
            wz   = wz.';
        end
        
        % Remove additional point
        if length(n_or_w)>1,
            if addpoint==1,
                Hz(end) =[];
                phiz(end)=[];
                wz(end)=[];
            elseif addpoint==-1,
                Hz(1) =[];
                phiz(1)=[];
                wz(1)=[];
            end
        end
        
        % Update options
        options.periodicity = periodicity;
        options.flip = flip;
        options.nfft = length(wz);
        options.w    = wz;
    end
else
    [Hz,wz,phiz,options,s] = zerophase(b(1,1:3), b(1,4:6), varargin{:});
    for indx = 2:size(b, 1),
        [h,~,phi] = zerophase(b(indx,1:3), b(indx,4:6), varargin{:});
        Hz = Hz.*h;
        phiz = phiz+phi;
    end
end
% Cast to enforce Precision rules
wz = double(wz);
options.w    = wz;

% Cast to enforce precision rules
% Only cast if output is requested, otherwise, plot using double precision
% frequency vector. 
if nargout > 1 && isa(Hz,'single')
  wz = single(wz);
end

% Parse outputs
switch nargout
    case 0
        zerophaseplot(Hz,wz,s);
    case 1
        varargout = {Hz};
    case 2
        varargout = {Hz,wz};
    case 3
        varargout = {Hz,wz,phiz};
    case 4
        varargout = {Hz,wz,phiz,options};
    case 5
        varargout = {Hz, wz, phiz, options, s};
end

%--------------------------------------------------------------------------------------------
function [Hz,Wz,Phi,S, options,errStr] = exactzerophase(b, varargin)
% Compute the zerophase from the frequency response.
% References: A. Antoniou, DIGITAL FILTERS, Analysis, Design, and
%             Applications. 2nd Ed., Mc Graw-Hill, N.Y., 1993,
%             Chapter 15.

Hz = [];
Wz = [];
Phi = [];
S = [];
options = [];
errStr = '';

if ~signalpolyutils('islinphase',b,1),
    errStr = getString(message('signal:zerophase:TheFilterMustHaveLinearPhase'));
    return
end

lastidx = find(b, 1, 'last');
if ~isempty(lastidx),
    % Remove trailing zeros
    b = b(1:lastidx);
    % Get the number of leading zeros.
    nzeros=find(b, 1)-1;
else
    % Trivial case: the filter is all zeros
    nzeros = 0;
end

% Get the FIR type and filter order
if length(b) == 1,
    filtertype = 1;
    N = 0;
else
    N = length(b) - 1; % Filter order.
    
    if strcmpi('symmetric',signalpolyutils('symmetrytest',b,1)),
        % Symmetric coefficients
        issymflag = 1;
    else
        % We already know it is linear phase, must be antisymmetric coefficients
        issymflag = 0;
    end
    
    filtertype = determinetype(N,issymflag);
end

% Compute the frequency response (freqz)
try
    [H, Wz, S, options] = freqz(b,1,varargin{:});
    % Compute the frequency vector W
    W = computeFreqv(Wz,S);
catch  ME
    errStr = ME.message;
    return
end

% Compute the phase component Phi = P - Nw/2
% P = 0 for Type 1 and 2 FIR filters.
% P = pi/2 for Type 3 and 4 FIR filters.

flip = 0;
switch filtertype
    case {1,2}
        P=0;
        periodicity = 2;
        if filtertype==2,
            periodicity = 4;
        end
    case {3,4}
        P=pi/2;
        periodicity = 2;
        if filtertype==4,
            periodicity = 4;
            flip = 1;
        end
end
options.periodicity = periodicity;
options.flip = flip;
Phi=P-W*((N+nzeros)/2); % Phase component
% Cast to enforce Precision rules
if (isa(b,'single'))
    Phi = single(Phi);
end

% The zerophase response : Hzero = exp(-J*Phi)*H(w)

ejnw=exp(-1i*Phi); % exponential multiplying factor
Hz=real(H.*ejnw); % zerophase response, disregard the round off imaginary part.


%------------------------------------------------------------------------------------
function filtertype = determinetype(N,issymflag)

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


%---------------------------------------------------------------------------------------------
function W = computeFreqv(Wz,S)
% Compute the frequency vector W which will be used in the phase component.

% If Fs was not specified return W = Wz
if isempty(S.Fs)
    W = Wz;
else
    W = 2*pi*Wz/S.Fs;
end


%--------------------------------------------------------------------------------------------
function phi = compute_phase(b, a, upn_or_w, options)
% Compute the phase response (phasez) on the desired range

phi = phasez(b, a, upn_or_w, options{:});


%---------------------------------------------------------------------------------------------
function [Hsign, isfirstsegmentpositive, periodicity, flip] = estimateHsign(b, ...
    a, phi, iswholerange, upn_or_w)

%--------------------------------------------------------------------------
% Estimate the sign of H on the [0 Fs/2) range
%--------------------------------------------------------------------------

if all(isnan(phi))
  error(message('signal:zerophase:FilterBadlyScaled'));
end

% Detect the discontinuities of the phase on [0 Fs/2)
N = length(phi);
if iswholerange,
    N = N/2;
end
phasejumps = findphasejumps(phi(1:N));

 % Determine the sign of the first point
ii = 1;
while ii<=numel(length(phi)) && isnan(phi(ii)),
    ii=ii+1;
end
if ii==1,
    H0 = dividenowarn(sum(b),sum(a));
    isfirstsegmentpositive = sign(H0)/2+.5; % first point positive=1 , negative or null=0
else  
    isfirstsegmentpositive = sign(phi(ii))/2+.5;
end

% Determine the length of each segment where the sign is constant
signlength = diff(phasejumps); % Phase jump = Sign change

% Build the sign by concatenating segments of 1 and -1 alternatively
Hsign = [];
for ii=1:length(signlength),
    Hsign = [Hsign; (-1)^(ii+isfirstsegmentpositive)*ones(signlength(ii),1)];  %#ok<AGROW>
end

%--------------------------------------------------------------------------
% Extend the estimation of the sign of H on the full range [0 Fs) if needed
%--------------------------------------------------------------------------
periodicity = [];
flip = 0;
if iswholerange,
    % Determine the symetries of the zerophase
    [sym_0, sym_pi, periodicity, flip] = findsym(phi, upn_or_w);
    if sym_0 && sym_pi,
        % Symmetry vs 0 and pi
        Hsign = [Hsign(:);Hsign(end:-1:1)];
    elseif sym_0,
        % Symmetry vs 0 and anti-symmetry vs pi
        Hsign = [Hsign(:);-Hsign(end:-1:1)];
    elseif sym_pi,
        % Anti-symmetry vs 0 and symmetry vs pi
        Hsign = [Hsign(:);Hsign(end:-1:1)];
    else
        % Anti-symmetry vs 0 and anti-symmetry vs pi
        Hsign = [Hsign(:);-Hsign(end:-1:1)];
    end
end


%--------------------------------------------------------------------------------------------
function phasejumps = findphasejumps(Phi)

% First source of jumps: gaps greter than pi*170/180
phasejumps1 = gaps(Phi);

% Second source of jumps: NaNs
phasejumps2 = findnans(Phi);

% Union of all phase jumps
phasejumps = union(phasejumps1, phasejumps2);


%--------------------------------------------------------------------------------------------
function phasejumps = gaps(Phi)

% Detect the jumps greater than pi*170/180 (non-linearities)
phasejumps = find(abs(diff(Phi))>pi*170/180);

% First and last points = non-linearities
phasejumps = [0; phasejumps; length(Phi)];

% Add 1 because of diff
phasejumps = phasejumps+1;



%--------------------------------------------------------------------------------------------
function phasejumps = findnans(Phi)

% Find NaNs
nans=find(isnan(Phi));

if isempty(nans),
    phasejumps = [];
else
    % First NaN
    firstnan = nans(1);
    nans(1) = [];
    
    % Keep the first of consecutive NaNs
    index = isnan(Phi(nans-1));
    nans(index) = [];
    phasejumps = [firstnan;nans(:)];
end

%--------------------------------------------------------------------------------------------
function [sym_0, sym_pi, periodicity, flip] = findsym(phi, upn_or_w)

% Determination of the symmetry vs 0
sym_0 = issymmetric(phi, 0);

% Determination of the symmetry vs pi
if length(upn_or_w)==1,
    % Nfft
    npi = upn_or_w/2;
end
sym_pi = issymmetric(phi, npi);

flip = 0;
if sym_0 && sym_pi,
    % Symmetry vs 0 and pi
    periodicity = 2;
elseif sym_0,
    % Symmetry vs 0 and anti-symmetry vs pi
    periodicity = 4;
elseif sym_pi,
    % Anti-symmetry vs 0 and symmetry vs pi
    periodicity = 2;
else
    % Anti-symmetry vs 0 and anti-symmetry vs pi
    periodicity = 4;
    flip = 1;
end


%--------------------------------------------------------------------------------------------
function sym_val = issymmetric(phi, val)
% Determination of the symmetry vs val

phitol=pi/10;
i = val+1;
while isnan(phi(i)),
    i=i+1;
end

if i==val+1,
    sym_val=1; % symmetry vs val
else
    % Principal component of the phase (between -pi and pi)
    princomp = rem(phi(i),pi);
    if abs(princomp)>pi/2-phitol && abs(princomp)<pi/2+phitol,
        % Jump of pi in the vicinity of val
        sym_val=0; % antisymmetry vs val
    else
        sym_val=1; % symmetry vs val
    end
end


%--------------------------------------------------------------------------------------------
function [h, wz, s, options] = compute_fresp(b, a, upn_or_w, options)

[h, wz, s, options] = freqz(b, a, upn_or_w, options{:});


%-----------------------------------------------------------------------------------------------
function phiz = compute_continuousphase(Hsign, phi, isfirstsegmentpositive)

% Compensate the phase (-pi on each discontinuity section)
aux = [0; diff((Hsign-1)/2)];
compensate = cumsum(abs(aux));
phiz = phi(:)-compensate*pi;

% Add an offset to the phase if the first segment is negative
% The first point of Phiz must be -pi and pi
if ~isfirstsegmentpositive,
    if phiz(1)>=0,
        phiz=phiz-pi;
    else
        phiz=phiz+pi;
    end
end


%-----------------------------------------------------------------------------------------------
function zerophaseplot(Hz,Wz,S)

% Determine the correct frequency label.
if isempty(S.Fs),
    xlbl = [getString(message('signal:zerophase:NormalizedFrequency')) ' (\times \pi rad/sample)'];
    Wz = Wz./pi;
else
    xlbl = getString(message('signal:zerophase:FrequencyHz'));
end

ylbl = getString(message('signal:zerophase:Amplitude'));

% Plot the zero-phase response
h_plot = plot(Wz,Hz);

% Set axis limit to last frequency value and turn grid on
h_axis = get(h_plot,'parent');
set(h_axis,'xlim',[Wz(1),Wz(end)],'xgrid','on','ygrid','on');

% Set x-label
h_xlbl = get(h_axis,'xlabel');
set(h_xlbl,'string',xlbl);

% Set y-label
h_ylbl = get(h_axis,'ylabel');
set(h_ylbl,'string',ylbl);

% Set title
h_title = get(h_axis,'title');
set(h_title,'string','Zero-phase response');

% [EOF]

function varargout = phasez(b,varargin)
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
[upn_or_w, upfactor, iswholerange, options, addpoint] = findfreqvector(varargin{:});

% Compute the frequency response (freqz)
if isTF
  % Checks if B and A are valid numeric data inputs
   
  % freqz casts inputs without single precision bearing (N, F and Fs) to
  % double
  [h, w, s, options] = freqz(b, a, upn_or_w, options{:});
  
  % Extract phase from frequency response
  [phi,w] = extract_phase(h,upn_or_w,iswholerange,upfactor,w,addpoint);
else
  %Compute phase for individual sections, not on the entire SOS matrix to
  %avoid close-to-zero responses. Add phase of individual sections.  
  [h, w, s, options1] = freqz(b(1,1:3), b(1,4:6), upn_or_w, options{:});
  [phi,w] = extract_phase(h,upn_or_w,iswholerange,upfactor,w,addpoint);
  for indx = 2:size(b, 1)
    h = freqz(b(indx,1:3), b(indx,4:6), upn_or_w, options{:});
    phi = phi + extract_phase(h,upn_or_w,iswholerange,upfactor,w,addpoint);            
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
        phaseplot(phi,w,s);
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
function phaseplot(phi,w,s)

% Cell array of the standard frequency units strings (used for the Xlabels)
frequnitstrs = getfrequnitstrs;
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
function [n_or_w, options, do_transpose] = extract_norw(varargin)
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
function [upn_or_w, upfactor, iswholerange, do_transpose] = getinterpfrequencies(n_or_w, varargin)
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
function [upn_or_w, upfactor, iswholerange, options, addpoint] = findfreqvector(varargin)
%FINDFREQVECTOR Define the frequency vector where the phase is evaluated.

%   Author(s): V.Pellissier
%   Copyright 2005 The MathWorks, Inc.


% Parse inputs
[n_or_w, options] = extract_norw(varargin{:});

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
[upn_or_w, upfactor, iswholerange] = getinterpfrequencies(n_or_w, varargin{:});

function [hh,w,s,options] = freqz(b,varargin)
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

[options,msg,msgobj] = freqz_options(varargin{:});
if ~isempty(msg)
    error(msgobj);
end

if isTF
% Checks if B and A are valid numeric data inputs

    if length(a) == 1
        [h,w,options] = firfreqz(b/a,options);
    else
        [h,w,options] = iirfreqz(b,a,options);
    end
else
    validateattributes(b,{'double','single'},{},'freqz');   
    [h,w,options] = sosfreqz(b,options);
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
        phi = phasez(b,a,varargin{:});
    else
        phi = phasez(b,varargin{:});
    end
    
    data(:,:,1) = h;
    data(:,:,2) = phi;
    ws = warning('off'); %#ok<WNOFF>
    freqzplot(data,w,s,'magphase');
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
function [h,w,options] = firfreqz(b,options)

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
        b = datawrap(b,s.*nfft);
    end
    
    % dividenowarn temporarily shuts off warnings to avoid "Divide by zero"
    h = fft(b,s.*nfft).';
    % When RANGE = 'half', we computed a 2*nfft point FFT, now we take half the result
    h = h(1:nfft);
    h = h(:); % Make it a column only when nfft is given (backwards comp.)
    w = freqz_freqvec(nfft, Fs, s);
    w = w(:); % Make it a column only when nfft is given (backwards comp.)
end

%--------------------------------------------------------------------------
function [h,w,options] = iirfreqz(b,a,options)
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
        b = datawrap(b,s.*nfft);
        a = datawrap(a,s.*nfft);
    end
    
    % dividenowarn temporarily shuts off warnings to avoid "Divide by zero"
    h = dividenowarn(fft(b,s.*nfft),fft(a,s.*nfft)).';
    % When RANGE = 'half', we computed a 2*nfft point FFT, now we take half the result
    h = h(1:nfft);
    h = h(:); % Make it a column only when nfft is given (backwards comp.)
    w = freqz_freqvec(nfft, Fs, s);
    w = w(:); % Make it a column only when nfft is given (backwards comp.)
end
%--------------------------------------------------------------------------
function [h,w,options] = sosfreqz(sos,options)

[h, w] = iirfreqz(sos(1,1:3), sos(1,4:6), options);
for indx = 2:size(sos, 1)
    h = h.*iirfreqz(sos(indx,1:3), sos(indx,4:6), options);
end

%-------------------------------------------------------------------------------
function [options,msg,msgobj] = freqz_options(varargin)
%FREQZ_OPTIONS   Parse the optional arguments to FREQZ.
%   FREQZ_OPTIONS returns a structure with the following fields:
%   options.nfft         - number of freq. points to be used in the computation
%   options.fvflag       - Flag indicating whether nfft was specified or a vector was given
%   options.w            - frequency vector (empty if nfft is specified)
%   options.Fs           - Sampling frequency (empty if no Fs specified)
%   options.range        - 'half' = [0, Nyquist); 'whole' = [0, 2*Nyquist)


% Set up defaults
options.nfft   = 512;
options.Fs     = [];
options.w      = [];
options.range  = 'onesided';
options.fvflag = 0;
isreal_x       = []; % Not applicable to freqz

[options,msg,msgobj] = psdoptions(isreal_x,options,varargin{:});

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
function [options,msg,msgobj] = psdoptions(isreal_x,options,varargin)
%PSDOPTIONS   Parse the optional inputs to most psd related functions.
%
%
%  Inputs:
%   isreal_x             - flag indicating if the signal is real or complex
%   options              - the same structure that will be returned with the
%                          fields set to the default values
%   varargin             - optional input arguments to the calling function
%
%  Outputs:
%  PSDOPTIONS returns a structure, OPTIONS, with following fields:
%   options.nfft         - number of freq. points at which the psd is estimated
%   options.Fs           - sampling freq. if any
%   options.range        - 'onesided' or 'twosided'
%   options.centerdc     - true if 'centered' specified
%   options.conflevel    - confidence level between 0 and 1 ('omitted' when unspecified)
%   options.ConfInt      - this field only exists when called by PMTM 
%   options.MTMethod     - this field only exists when called by PMTM
%   options.NW           - this field only exists when called by PMUSIC (see PMUSIC for explanation)
%   options.Noverlap     - this field only exists when called by PMUSIC (see PMUSIC for explanation)
%   options.CorrFlag     - this field only exists when called by PMUSIC (see PMUSIC for explanation)
%   options.EVFlag       - this field only exists when called by PMUSIC (see PMUSIC for explanation)



%  Authors: D. Orofino and R. Losada
%  Copyright 1988-2012 The MathWorks, Inc.
   
[s,msg,msgobj] = psd_parse(varargin{:});
if ~isempty(msg),
   return
end

omit = 'omitted';

% Replace defaults when appropriate

% If empty or omitted, nfft = default nfft (default is calling function dependent)
if ~any([isempty(s.NFFT),strcmp(s.NFFT,omit)]),    
   options.nfft = s.NFFT;   
end

if ~strcmp(s.Fs,omit), % If omitted, Fs = [], work in rad/sample
   options.Fs = s.Fs;
   if isempty(options.Fs),
      options.Fs = 1;  % If Fs specified as [], use 1 Hz as default
   end
end

% Only PMTM has the field options.ConfInt; 
if isfield(options,'ConfInt'),
   if ~strcmp(s.ConfInt,omit) && ~isempty(s.ConfInt),
      % Override the default option ONLY if user specified a new value
      options.ConfInt = s.ConfInt;
   end
else
   % If a third scalar was specified, error out unless PMUSIC is the calling function
   % (hence options.NW exists)
   if ~strcmp(s.ConfInt,omit) && ~isfield(options,'nw'),  
      msgobj = message('signal:psdoptions:TooManyNumericOptions');
      msg = getString(msgobj);
      return
   end
end

% Only PMUSIC has the field options.nw; 
if isfield(options,'nw'),
   if ~strcmp(s.nw,omit) && ~isempty(s.nw),
      % Override the default option ONLY if user specified a new value
      options.nw = s.nw;
      if ~any(size(options.nw)==1),
         msgobj = message('signal:psdoptions:MustBeScalarOrVector','NW');
         msg = getString(msgobj);
         return
      elseif length(options.nw) > 1,
         options.window = options.nw;
         options.nw = length(options.nw);
      end
   end
else
   % If a third scalar was specified, error out unless PMTM is the calling function
   % (hence options.ConfInt exists)
   if ~strcmp(s.nw,omit) && ~isfield(options,'ConfInt'),  
      msgobj = message('signal:psdoptions:TooManyNumericOptions');
      msg = getString(msgobj);
      return
   end
end

% Only PMUSIC has the field options.noverlap; 
if isfield(options,'noverlap'),
   if ~strcmp(s.noverlap,omit) && ~isempty(s.noverlap),
      % Override the default option ONLY if user specified a new value
      options.noverlap = s.noverlap;
   else
      % Use default
      options.noverlap = options.nw -1;
   end
end
 
options.centerdc = ~strcmp(s.DCFlag,'omitted');
options.conflevel = s.ConfLevel;

if ~strcmp(s.Range,omit),
   options.range = s.Range;
end

if ~isreal_x & strcmpi(options.range,'onesided'), %#ok
   msgobj = message('signal:psdoptions:ComplexInputDoesNotHaveOnesidedPSD');
   msg = getString(msgobj);
   return
end

% Only PMTM has the field options.MTMethod
if ~isfield(options,'MTMethod'),
   if ~strcmp(s.MTMethod,omit),
      % A string particular to pmtm is not supported here
      msgobj = message('signal:psdoptions:UnrecognizedString');
      msg = getString(msgobj);
      return
   end
elseif ~strcmp(s.MTMethod,omit),
   % Override the default option ONLY if user specified a new value
   % psd_parse has already determined the validity of this string
   options.MTMethod = s.MTMethod; 
end

% Only PMUSIC has the field options.CorrFlag
if ~isfield(options,'CorrFlag'),
   if ~strcmp(s.CorrFlag,omit),
      % A string particular to pmusic is not supported here
      msgobj = message('signal:psdoptions:UnrecognizedString');
      msg = getString(msgobj);
      return
   end
elseif ~strcmp(s.CorrFlag,omit),
   % Override the default option ONLY if user specified a new value
   % psd_parse has already determined the validity of this string, we set the flag to one
   options.CorrFlag = 1; 
end

% Only PMUSIC has the field options.EVFlag
if ~isfield(options,'EVFlag'),
   if ~strcmp(s.EVFlag,omit),
      % A string particular to pmusic is not supported here
      msgobj = message('signal:psdoptions:UnrecognizedString');
      msg = getString(msgobj);
      return
   end
elseif ~strcmp(s.EVFlag,omit),
   % Override the default option ONLY if user specified a new value
   % psd_parse has already determined the validity of this string, we set the flag to one
   options.EVFlag = 1; 
end


%------------------------------------------------------------------------------
function [s,msg,msgobj] = psd_parse(varargin)
%PSD_PARSE Parse trailing inputs for PSD functions.
%  [S,MSG] = PSD_PARSE(varargin) parses the input argument list and
%  returns a structure, S, with fields corresponding to each of the
%  possible PSD options.  If an option is omitted, a default value
%  is returned such that the structure will always return a value
%  for every possible option field.
%
%  MSG is a error message returned from the parse operation.
%  It may be empty, in which case no parsing errors have occurred.
%
%  The structure fields are as follows:
%   S.NFFT    - FFT length (scalar).  If it appears in the argument
%               list, it must be the 1st scalar argument, but not
%               necessarily the 1st argument in the list.  A string option
%               could occur before, instead of, or after this option.
%               If omitted, 'omitted' is returned.
%
%   S.Fs      - Sample rate in Hz (scalar).  If it appears in the argument
%               list, it must be the 2nd scalar argument, but not
%               necessarily the 2nd argument in the list.  A string option
%               could occur before, instead of, or after this option.
%               If omitted, 'omitted' is returned.
%
%   S.ConfInt - Confidence interval (scalar).  If it appears in the argument
%   S.nw        list, it must be the 3rd scalar argument, but not
%   (synonyms)  necessarily the 3rd argument in the list.  A string option
%               could occur before, instead of, or after this option.
%               If omitted, 'omitted' is returned.
%               NOTE: Only pmusic expects S.NW at present, and S.ConfInt and
%               S.NW are simply synonyms of each other (both are set to exactly
%               the same values).
%
%   S.ConfLevel Confidence level property value (scalar) between 0 and 1.
%               If omitted, 'omitted' is returned.  This property does not
%               interfere with S.ConfInt which is used only with PMTM.
%
%   S.DCFlag  - CenterDC.  Returns true iff 'centered' is specified in the argument
%               list.  Recognized argument strings: 'centered'
%
%   S.noverlap  Sample overlap (scalar).  If it appears in the argument list,
%               it must be the 4th scalar argument, but not necessarily the
%               4th argument in the list.  A string option could occur before,
%               instead of, or after this option.  If omitted, 'omitted' is
%               returned.  NOTE: Only pmusic expects S.NOverlap at present.
%
%   S.Range   - X-axis scaling method (string).  This option is specified in
%               the argument list as one of the mutually exclusive strings
%               specified in the list below.  Note that any case (including
%               mixed) will be accepted, including partial unique string matching.
%               This option may appear anywhere in the argument list.  The
%               structure field is set to the full name of the option string
%               as provided in the list below.  If omitted, 'omitted' is returned.
%               Recognized argument strings:
%                       Input             Field Contents
%                       'half'            'one-sided'
%                       'whole'           'two-sided'
%                       'one-sided'       'one-sided'
%                       'two-sided'       'two-sided'
%               NOTE: The hyphens may be omitted or replaced with a single space.
%
%   S.MTMethod -MTM method name (string).  This option is specified in
%               the argument list as one of the mutually exclusive strings
%               specified in the list below.  Note that any case (including
%               mixed) will be accepted, including partial unique string matching.
%               This option may appear anywhere in the argument list.  The
%               structure field is set to the full name of the option string
%               as provided in the list below.  If omitted, 'omitted' is returned.
%               Recognized argument strings: 'adapt', 'eigen', 'unity'.
%
%   S.CorrFlag -Method for pmusic (string).  This option is specified in
%               the argument list as one of the mutually exclusive strings
%               specified in the list below.  Note that any case (including
%               mixed) will be accepted, including partial unique string matching.
%               This option may appear anywhere in the argument list.  The
%               structure field is set to the full name of the option string
%               as provided in the list below.  If omitted, 'omitted' is returned.
%               Recognized argument strings: 'corr'
%
%  s.EVFlag   - Eigenvector method for pmusic (string).  This option is specified in
%               the argument list as one of the mutually exclusive strings
%               specified in the list below.  Note that any case (including
%               mixed) will be accepted, including partial unique string matching.
%               This option may appear anywhere in the argument list.  The
%               structure field is set to the full name of the option string
%               as provided in the list below.  If omitted, 'omitted' is returned.
%               Recognized argument strings: 'EV'


% Initialize return arguments
msg        = '';
msgobj     = [];
omit       = 'omitted';
s.NFFT     = omit;
s.Fs       = omit;
s.ConfInt  = omit;
s.Range    = omit;
s.MTMethod = omit;
s.nw       = omit;
s.noverlap  = omit;
s.CorrFlag = omit;
s.EVFlag   = omit;
s.DCFlag   = omit;
s.ConfLevel = omit;

% look for conflevel pv pair and set flag if user-specified
matchIdx = strcmpi('ConfidenceLevel',varargin);
numMatches = sum(matchIdx(:));
if numMatches>1
   msgobj = message('signal:psdoptions:MultipleValues');
   msg = getString(msgobj);
   return
elseif numMatches == 1
   pIdx = find(matchIdx);
   if pIdx == numel(varargin)
      msgobj = message('signal:psdoptions:MissingConfLevelValue');
      msg = getString(msgobj);
      return
   end
   % obtain the property value.
   confLevel = varargin{pIdx+1};
   if isscalar(confLevel) && isreal(confLevel) && 0<confLevel && confLevel<1
      s.ConfLevel = confLevel;
   else
      msgobj = message('signal:psdoptions:InvalidConfLevelValue');
      msg = getString(msgobj);
      return
   end
   % remove the pv-pair from the argument list
   varargin([pIdx pIdx+1]) = [];    
end

% look for flags

% Define all possible string options
% Lower case, no punctuation:
strOpts = {'half','onesided','whole','twosided', ...
           'adapt','unity','eigen', ...
           'corr', 'ev', ...
           'centered'};

% Check for mutually exclusive options
exclusiveOpts = strOpts([1 3; 2 4; 5 6; 5 7; 6 7; 1 10; 2 10]);
for i=1:size(exclusiveOpts,1)
   if any(strcmpi(exclusiveOpts(i,1),varargin)) && ...
         any(strcmpi(exclusiveOpts(i,2),varargin))
     msgobj = message('signal:psdoptions:ConflictingOptions', ...
                      exclusiveOpts{i,1}, exclusiveOpts{i,2});
     msg = getString(msgobj);
     return
   end
end

% No options passed - return all defaults:
if numel(varargin)<1, return; end

numReals = 0;  % Initialize count of numeric options

for argNum=1:numel(varargin),
   arg = varargin{argNum};
   
   isStr     = ischar(arg);
   isRealVector = isnumeric(arg) & ~issparse(arg) & isreal(arg) & any(size(arg)<=1);
   isValid   = isStr | isRealVector;
   
   if ~isValid,
      msgobj = message('signal:psdoptions:NeedValidOptionsType');
      msg = getString(msgobj);
      return;
   end
   
   if isStr,
      % String option
      %
      % Convert to lowercase and remove special chars:
      arg = RemoveSpecialChar(arg);
      
      % Match option set:
      i = find(strncmp(arg, strOpts, length(arg)));
      if isempty(i) || length(i)>1,
         msgobj = message('signal:psdoptions:UnknStringOption');
         msg = getString(msgobj);
         return
      end
      
      % Determine option set to which this string applies:
      switch i
      case {1,2,3,4},
         field = 'Range';
      case {5,6,7},
         field = 'MTMethod';
      case 8,
         field = 'CorrFlag';
      case 9,
         field = 'EVFlag';
      case 10,
         field = 'DCFlag';
      otherwise,
         error(message('signal:psdoptions:IdxOutOfBound'));
      end
      
      % Verify that no other options from (exclusive) set have
      % already been parsed:
      existingOpt = s.(field);
      if ~strcmp(existingOpt,'omitted'),
         msgobj = message('signal:psdoptions:MultipleValues');
         msg = getString(msgobj);
         return
      end
      
      % Map half to one-sided (index 1 -> index 2)
      % Map whole to two-sided (index 3 -> index 4)
      if i==1 || i==3,
         i=i+1;
      end
      
      % Set full option string into appropriate field:
      s.(field) = strOpts{i};
      
   else
      % Non-string options
      %
      numReals = numReals + 1;
      switch numReals
      case 1, s.NFFT    = arg;
      case 2,
         if length(arg)<=1,
            s.Fs = arg;
         else
            msgobj = message('signal:psdoptions:FsMustBeScalar');
            msg = getString(msgobj);
            return
         end
      case 3,
            s.ConfInt = arg;
            s.nw = arg;  % synonym
            
            % NOTE: Cannot error out for non-scalars, as NW may be a vector!
            %       We cannot disambiguate ConfInt from NW strictly from context.
            %
            %if length(arg)<=1,
            %   s.ConfInt = arg;
            %else
            %   msg = 'The confidence interval must be a scalar.';
            %   return
            %end
      case 4,
         if length(arg)<=1,
            s.noverlap = arg;
         else
            msgobj = message('signal:psdoptions:OverlapMustBeScalar');
            msg = getString(msgobj);
            return
         end
      otherwise
         msgobj = message('signal:psdoptions:TooManyNumericOptions');
         msg = getString(msgobj);
         return
      end
   end
   
end


%--------------------------------------------------------------------------------
function y=RemoveSpecialChar(x)
% RemoveSpecialChar
%   Remove one space of hyphen from 4th position, but
%   only if first 3 chars are 'one' or 'two'

y = lower(x);

% If string is less than 4 chars, do nothing:
if length(y)<=3, return; end

% If first 3 chars are not 'one' or 'two', do nothing:
if ~strncmp(y,'one',3) && ~strncmp(y,'two',3), return; end

% If 4th char is space or hyphen, remove it
if y(4)==' ' || y(4) == '-', y(4)=''; end

% [EOF] psdoptions.m

function [phi,w] = extract_phase(h,upn_or_w,iswholerange,upfactor,w,addpoint)
%EXTRACT_PHASE Extract phase from frequency response  

%   Author(s): V. Pellissier
%   Copyright 2005 The MathWorks, Inc.

% When h==0, the phase is not defined (introducing NaN's)
h = modify_fresp(h);

% Unwrap the phase
phi = unwrap_phase(h,upn_or_w,iswholerange);

% Downsample
phi = downsample(phi, upfactor);
w = downsample(w, upfactor);

% Remove additional point
if addpoint==1,
    phi(end)=[];
    w(end)=[];
elseif addpoint==-1,
    phi(1)=[];
    w(1)=[];
end

%-------------------------------------------------------------------------------
function h = modify_fresp(h)
% When h==0, the phase is not defined (introducing NaN's)

tol = eps^(2/3);
ind = find(abs(h)<=tol);
if ~isempty(ind);
    h(ind)=NaN;
end

%-------------------------------------------------------------------------------
function phi = unwrap_phase(h,w,iswholerange)

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
function y = downsample(x,N,varargin)
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

y = updownsample(x,N,'Down',varargin{:});

% [EOF] 

function y = updownsample(x,N,str,varargin)
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

phase = parseUpDnSample(str,N,varargin{:});
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
function phase = parseUpDnSample(str,N,varargin)
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

function y = dividenowarn(num,den)
% DIVIDENOWARN Divides two polynomials while suppressing warnings.
% DIVIDENOWARN(NUM,DEN) array divides two polynomials but suppresses warnings 
% to avoid "Divide by zero" warnings.

%   Copyright 1988-2002 The MathWorks, Inc.

s = warning; % Cache warning state
warning off  % Avoid "Divide by zero" warnings
y = (num./den);
warning(s);  % Reset warning state

% [EOF] dividenowarn.m