% Concrete singleton implementation
classdef LUTi <handle
    %{
func = @(x) sin(pi/2*x);
N_BIT_LUT = 32;
N_BIT_IN = 5;
N_LUT_BIN = 2^7;


tLUT = (0:N_LUT_BIN)/(N_LUT_BIN-1/(2^N_BIT_IN/N_LUT_BIN));

yLUT = func(tLUT);
lutobj = LUTi(uint64(yLUT*(2^N_BIT_LUT-1)),N_BIT_LUT);


tQ =(0:2^N_BIT_IN-1)'/(2^N_BIT_IN-1);


y_hat = double(lutobj.at(uint64(tQ*(2^N_BIT_IN-1)),N_BIT_IN))/(2^N_BIT_LUT-1);
y_grt = func(tQ);

subplot(211)
plot(tLUT,yLUT,'p-',tQ,y_hat,'o-',tQ,y_grt,'s-','markersize',10)
lutobj.memsizeKB();
subplot(212)
plot(abs(y_grt-y_hat))
    %}
    properties (Access=private)
        m_lut;
        m_bitaccuracy;
    end
    
    
    
    
    
    methods (Static=true, Access=private)
    end
    
    methods (Access=private)
    end
    
    methods (Access=public)
        
        function newObj = LUTi(lutin,dataYbits)
            newObj.m_lut = lutin(:); %lutin must be in size of 2^k+1 (2^k bins, 2^k+1 borders between bins)
            if(mod(log(length(lutin)-1)/log(2),1)~=0)
                error('LUT size should be a power of 2 (plus one)');
            end
            if(any(newObj.m_lut>2^dataYbits-1))
                error('Input data is to big for requested LUT bit size');
            end
            
            
            newObj.m_bitaccuracy = dataYbits;
            
        end
        
        function s=memsizeKB(obj)
            s =  length(obj.m_lut)*obj.m_bitaccuracy/(8*1024);
            
        end
        
        function val = at(obj,xi,datXbits) %c style input
            sz = size(xi);
            xi=xi(:);
            createmsk = @(b) uint64(bitshift(1,b)-1);
            nLUTbins = length(obj.m_lut)-1;%obj.m_lut is in size of 2^k+1, so nLUTbins = 2^k
            lutXbits = log(nLUTbins)/log(2);% lutXbits == k 
%             lutYbits = obj.m_bitaccuracy;
            
%             if(datXbits>lutYbits)
%                 error('LUT  #outbits(%d)<#inputbits(%d)',lutYbits,datXbits);
%             end
            intrpBits = datXbits-lutXbits;
            xiH0 = bitand(bitshift(uint64(xi),-(datXbits-lutXbits)),createmsk(lutXbits));
            xiH1 = min(xiH0+1,2^lutXbits);
            xiL0 = bitand(uint64(xi),createmsk(intrpBits));
            xiL1 = bitshift(1,intrpBits) - xiL0;
            val = ...
                uint64(obj.m_lut(xiH0+1)).*xiL1+...
                uint64(obj.m_lut(xiH1+1)).*xiL0;
            val = bitshift(val,-intrpBits);
            val = cast(val,'like',obj.m_lut);
            val = reshape(val,sz);
        end
    end
    
    
    
    
    
end












