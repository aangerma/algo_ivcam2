function a = fftplot(v,fSample,varargin)
if(any(size(v)==1))
    v=v(:);
end
if(mod(size(v,1),2)~=0)
    v(end,:) = [];
    warning('fftplot: input length should be even- removed last sample');
end
n = size(v,1);
if(~exist('fSample','var'))
    fSample = 1;
    xlbl = '$\frac{1}{pixel}$';
else
    xlbl = 'Frequency';
end
fx = linspace(0,fSample/2,n/2);
V = abs(fft(v));



    a=semilogy(fx,V(1:n/2,:)+eps,varargin{:});%+eps for 0 values of fft thet semilogy can't handle
    grid on;
    xlabel(xlbl,'interpreter','latex');
    ylabel('Power');

end