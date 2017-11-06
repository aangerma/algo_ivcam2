function quiverCmplx(ptA,ptB,varargin)
d = ptB-ptA;
quiver(real(ptA),imag(ptA),real(d),imag(d),varargin{:});
end