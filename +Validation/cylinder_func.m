function [f,df,w] = cylinder_func(x,y,p)
    height = p(1);
    diameter = p(2);
    rise = p(3);
    x0 = p(4);
    y0 = p(5);
    a = p(6);
    b = p(7);
    
    %helper functions
    eliptic = sqrt(((x-x0)./a).^2 + ((y-y0)./b).^2);
    g = exp(rise.*(eliptic-diameter));
    w = g*0;
    f = height./(g+1);
    
   w(f >= 0.9*height) =  1;
   w(f <  0.9*height & f>0.1*height) =  2;
   w(f <= 0.1*height) =  3;
    
    if nargout > 1
        eliptic = max(eliptic,eps);
        df = zeros(length(x),length(p));
        
        %derivative by height
        df(:,1) = 1./(g+1);
        
        %derivative by diamiter
        df(:,2) = (rise * height .* g)./((g+1).^2);
        
        %derivative by rise
        df(:,3) = -height * (eliptic - diameter) .* g ./((g+1).^2);
        
        %derivative by x0
        df(:,4) = -height * rise * (x - x0) .* g ./(a.^2.*eliptic.*((g+1).^2));
        
        %derivative by y0
        df(:,5) = -height * rise * (y - y0) .* g ./(b.^2.*eliptic.*((g+1).^2));
        
        %derivative by a
        df(:,6) = -height * rise * (x - x0).^2 .* g ./(a.^3.*eliptic.*((g+1).^2));
        
        %derivative by b
        df(:,7) = -height * rise * (y - y0).^2 .* g ./(b.^3.*eliptic.*((g+1).^2));
    end
end

