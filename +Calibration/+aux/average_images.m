function [IM_avg] = average_images(stream) 
    IM_avg = sum(double(stream),3)./sum(stream~=0,3);
end
