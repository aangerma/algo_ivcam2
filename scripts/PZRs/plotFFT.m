function varargout =  plotFFT(vec_in,varargin)
    %% Parse Arguments
    if isa(vec_in,'timeseries')
        vec = vec_in.Data;
        fs  = 1/vec_in.TimeInfo.Increment;
    else
        vec = vec_in;
        fs  = varargin{1};
    end
    
    if nargin>2
        do_plot =  varargin{2};
    else
        do_plot = true;
    end
    %% FFT
    
    
    vec_len = length(vec);
    dfreq = fs/vec_len;
    freq_axis = -dfreq*(vec_len/2):dfreq:dfreq*(vec_len/2-1);
    
    Fvec = fftshift(fft(vec,length(vec))); % fourier transformation
    
    if nargout>1 
        varargout{2} = freq_axis;
    end
    varargout{1} = Fvec;
    
    
    %     plot(freq_axis,abs(Fvec)/vec_len);
    if do_plot
        plot(freq_axis,db(Fvec/vec_len));
        xlabel('Freq[Hz]','FontSize',14);
        ylabel('Amplitude[dB]','Fontsize',14);
    end
end
