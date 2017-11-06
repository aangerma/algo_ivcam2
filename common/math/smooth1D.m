function yy = smooth1D(x,y,sig)
    y=y(:);
    if(isempty(x))
        x= (1:length(y))';
    else
        x=x(:);
    end
    n = length(y);
    if(isempty(x))
        x=1:n;
    end
    yy = zeros(n,1);
    for i=1:n;
        ker = exp(-0.5/sig^2*(x-x(i)).^2);
        ker = ker/sum(ker);
        yy(i) = y'*ker;
    end
end