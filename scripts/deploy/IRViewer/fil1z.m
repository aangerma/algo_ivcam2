
function varargout = fil1z(wn)
    
      [b,a]=butter(1,wn,'high');

%     a(1)=0;
%     a(2)=1;
%     
%     %     zrsLoc = roots([1 -1 -.5/(1-cos(wn*pi))]);
%     %     b(2) = zrsLoc(1);
%     
%     abr = ([1 -1 -.5/(1-cos(wn*pi))]);
%     b(2)=(-abr(2)+sqrt(abr(2)^2-4*abr(1)*abr(3)))/(2*abr(1));
%     
%     
%     b(1)=1-b(2);
    
    if(nargout==2)
        varargout{1}=b;
        varargout{2}=a;
    elseif(nargout==1)
        varargout{1}=[a;b];
    end
end
