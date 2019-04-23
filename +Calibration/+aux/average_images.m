function [IM_avg] = average_images(stream,unFiltered) 
    IM_avg = sum(double(stream),3)./sum(stream~=0,3);
    if(exist('unFiltered','var'))
        IM_avg = getFilteredImage(im,unFiltered);
    end
end

function imo=getFilteredImage(d,unFiltered)
    im=double(d);
    if ~unFiltered
        im(im==0)=nan;
        imv=im(Utils.indx2col(size(im),[5 5]));
        imo=reshape(nanmedian_(imv),size(im));
    end
    imo=normByMax(imo);
end
