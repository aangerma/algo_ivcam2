function [m,n] = numberOfSubplots(x)
    
    max_to_chk = ceil(sqrt(x));
    Y = 1:max_to_chk;
    Mat = Y'*Y;
    [n,m] = find(Mat>=x,1);
    
%     n*m >= x;
%     and(((n-1)*m)<x , (n*(m-1))<x );
end
