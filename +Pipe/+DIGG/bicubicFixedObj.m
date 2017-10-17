% Concrete singleton implementation
classdef bicubicFixedObj <handle
    
    properties (Access=private)
        lutFP;
        fs_xFP;
        fs_yFP;
        shift;%uint8
        x0;
        y0;
    end
    
    methods (Access=public)
        
        function newObj = bicubicFixedObj(lutFP_,fx_,fy_,shift_,x0_,y0_)
            if(~isa(lutFP_,'int64') || ~isa(fx_,'int64') || ~isa(fy_,'int64') || ~isa(shift_,'uint8'))
                error('bitshift should be uint8, lutFP/fx/fy should be int64');
            end
            
            newObj.shift = shift_;
            newObj.fs_xFP = fx_;
            newObj.lutFP = lutFP_;
            newObj.fs_yFP = fy_;
            newObj.x0 = x0_;
            newObj.y0 = y0_;
        end
        
        function [val,neighbors] = at(obj,X,Y)
            if(~isa(X,'int64') || ~isa(Y,'int64'))
                error('input to obj.at should be int64');
            end
            
            sz = size(X);
            XX = X(:) - obj.x0;
            YY = Y(:) - obj.y0;
            
            xindex = bitshift(XX*obj.fs_xFP,-double(obj.shift)); %bitshift func BUG - doesn't get uint8 in input 2
            yindex = bitshift(YY*obj.fs_yFP,-double(obj.shift));      
            
            
            [val,neighbors] = Pipe.DIGG.bicubicFixed(obj.lutFP, xindex, yindex, obj.shift);
            val = reshape(val,sz);
            neighbors = reshape(neighbors',[16 sz])';

        end
        
    end
end


















