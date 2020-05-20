function out = DirectInv(in)
    
    sz = size(in);
    out = eye(sz(1));
    
    % SLOWER IMPLEMENTATION
%     for row = 1:sz(1)
%         for col = 1:sz(2)
%             out(row,col) = (-1)^(row+col)*DirectDet(in([1:row-1,row+1:end],[1:col-1,col+1:end]));
%         end
%     end
%     out = out/DirectDet(in);

    % FASTER IMPLEMENTATION
    for row = 1:sz(1)
        out(row,:) = out(row,:)/in(row,row);
        in(row,:) = in(row,:)/in(row,row);
        factors = in(row+1:end,row)/in(row,row);
        out(row+1:end,:) = out(row+1:end,:) - factors.*out(row,:);
        in(row+1:end,:) = in(row+1:end,:) - factors.*in(row,:);
    end
    for row = sz(1):-1:1
        out(row,:) = out(row,:)-in(row,row+1:end)*out(row+1:end,:);
        in(row,:) = in(row,:)-in(row,row+1:end)*in(row+1:end,:);
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function out = DirectDet(in)
%     
%     sz = size(in);
%     if (sz(1)==2)
%         out = in(1,1)*in(2,2)-in(1,2)*in(2,1);
%     else
%         out = 0;
%         for row = 1:size(in,1)
%             out = out+(-1)^(row-1)*in(row,1)*DirectDet(in([1:row-1,row+1:end],2:end));
%         end
%     end
%     
% end

