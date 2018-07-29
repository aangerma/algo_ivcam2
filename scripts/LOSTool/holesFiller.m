function imout=holesFiller(imIn)
imout=double(imIn);
imout(imout==0)=nan;

for k=[3 5 7]
    indx = Utils.indx2col(size(imout),[k k]);
    bd=isnan(imout(:));
    if(~any(bd))
        break;
    end
    imoutv=imout(indx(:,bd));
    imout(bd)=nanmedian(imoutv);
end
imout=cast(imout,class(imIn));
end