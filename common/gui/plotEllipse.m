function  a = plotEllipse(varargin)
p = varargin{1};
t=linspace(0,2*pi,100);
if(length(p)==4)
    %streightend ellipse
    rr = p(3)^2/p(1)*0.25+p(4)^2/p(2)*0.25+1;
    a=plot(sqrt(rr/p(1))*cos(t) - p(3)/(2*p(1)),sqrt(rr/p(2))*sin(t) - p(4)/(2*p(2)),varargin{2:end});
else
    error('not supported');
end
end