function x = mysolve(f,y,x0,x1,eps)

while x1-x0 > eps
   
    x = 0.5*(x1+x0);
    fx = f(x);

    if fx<y,
       x0 = x;
    else
       x1 = x;
    end
        
end



