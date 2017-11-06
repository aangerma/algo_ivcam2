function yd = vectAtLinear(x,y,xd)
    x=x(:);
    y=y(:);
    xd=xd(:);
    
    if(isempty(x))
        indx_f=floor(xd);
        indx_f = min(length(y)-1,max(1,indx_f));
        indx_d = xd-indx_f;
        yd = y(indx_f).*(1-indx_d)+y(indx_f+1).*indx_d;
        return;
    end
    
    if(length(xd)~=1)
        yd = nan(size(xd));
        for i=1:length(xd)
            yd(i) = vectAtLinear(x,y,xd(i));
        end
        %     ydouble =arrayfun(@(z) vectAtLinear(x,y,z) ,indexDouble);
        return;
    end
    y=y(:);
    
    
    i1 = find(x-xd>0,1);
    if(isempty(i1))
        yd=y(end);
        return;
    end
    i0 = i1-1;
    
    if(i0<1)
        yd=y(1);
    elseif(i1>length(y))
        yd=y(end);
    else
        
        
        y0 = y(i0);
        y1 = y(i1);
        x0 = x(i0);
        x1 = x(i1);
        
        yd=(y1-y0)/(x1-x0)*(xd-x0)+y0;
    end
end