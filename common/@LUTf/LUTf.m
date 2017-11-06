% Concrete singleton implementation
classdef LUTf <handle
    %{
general integer(fixed-point) LUT with linear interpolation


example:

N_LUT_BIN = 2^8;
t =linspace(0,90,N_LUT_BIN);
dt = t(2)-t(1);
lutdata = sind(t);
lutobj = LUTf(lutdata,dt);

t_test = linspace(0,90,N_LUT_BIN*2^6);
sinH = lutobj.at(t_test);
sinG = sind(t_test);
plot(abs(sinG-sinH))
lutobj.memsizeKB()

    %}
    properties (Access=private)
        m_lut;
        m_fs;
    end
    
    
    
    
    
    methods (Static=true, Access=private)

    end
    
    methods (Access=private)
    end
    
    methods (Access=public)
        
        function newObj = LUTf(lutin,dx)
            
           
            newObj.m_fs = 1/dx;
            
            newObj.m_lut = single(lutin(:));
            
        end
        
        function s=memsizeKB(obj)
            s =  length(obj.m_lut)*32/1024;
            
        end
        
        function val = at(obj,xi)%C-style indexing!
%             assert(all(xi(:)>=0 & xi(:)<=(length(obj.m_lut)-1)/obj.m_fs),'input value should be 0<=x<=%d',round((length(obj.m_lut)-1)/obj.m_fs));
            sz = size(xi);
            xi=xi(:);
            ii = single(xi)*obj.m_fs; % index of the input x (i.e. x=90 -> ii=127 if m_lut is in [0,127])
            
            i0 = max(floor(ii),0); % the index round down
            i1 = min(i0+1,length(obj.m_lut)-1); % the index rounded up
            y0 = obj.m_lut(i0+1); % LUT value of index i0
            y1 = obj.m_lut(i1+1); % LUT value of index i1
            val=(y1-y0).*(ii-i0)+y0; %weighted mean of the input (linear interp)
            val = reshape(val,sz);
            
        end
        
    end
end


















