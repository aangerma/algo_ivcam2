function out = absgrad(in)
    switch(length(size(in)))
        case 1
            [x ]  = gradient(in);
            out = sqrt(x.^2);
            
        case 2
               [x, y]  = gradient(in);
               out = sqrt(x.^2+y.^2);
        case 3
            [x, y,z]  = gradient(in);
            out = sqrt(x.^2+y.^2+z.^2);
            
    end
end