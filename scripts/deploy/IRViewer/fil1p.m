
function varargout = fil1p(wn)
    
    
    
    a(1)=1;
    %     plsLoc = roots([1 4-2*cos(wn*pi) 1]);
    %     a(2) = plsLoc(1);
    
    abr = ([1 4-2*cos(wn*pi) 1]);
    a(2)=(-abr(2)+sqrt(abr(2)^2-4*abr(1)*abr(3)))/(2*abr(1));
    
    
    b(2)=1+a(2);
    b(1)=0;
    
    if(nargout==2)
        varargout{1}=b;
        varargout{2}=a;
    elseif(nargout==1)
        varargout{1}=[a;b];
    end
end
