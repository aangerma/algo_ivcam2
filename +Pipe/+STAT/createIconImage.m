function [ icn,vicn ] = createIconImage( R,V,lowThrPxlNum,CHSize,...
        CVSize, SkipH, SkipV,iconSize)
    
    %division lookup
    dLUT = uint32(power(2,16)./[1 1:64]);
    dLUT(1) = 0;
    %{
    if (CVSize == 0 || CHSize == 0)
        icn=R;
        vicn=V;
        return;
    end
    
    if(all(size(R)<iconSize))
        iconData = R;
        viconData = V;
    elseif(any(size(R)<iconSize))
        %TODO
        iconData=zeros(iconSize);
        viconData = zeros(iconSize);
    else
    %}
    %no loop implementation
    %skipVend = iconSize(1) (size(R,1)-SkipV)./CVSize
    %colsDepth = im2colDistinct(R(1+SkipV:size(R,1)-SkipV,1+SkipH:size(R,2)-SkipH),[CVSize,CHSize]);
    %colsInvalid = im2colDistinct(V(1+SkipV:size(R,1)-SkipV,1+SkipH:size(R,2)-SkipH),[CVSize,CHSize]);
    elemIndicator = ones(size(R));
    
    colsDepth = im2colDistinct(R(1+SkipV:end,1+SkipH:size(R,2)-SkipH),[CVSize,CHSize]);
    colsInvalid = im2colDistinct(V(1+SkipV:end,1+SkipH:size(R,2)-SkipH),[CVSize,CHSize]);
    numelCell = im2colDistinct(elemIndicator(1+SkipV:end,1+SkipH:size(R,2)-SkipH),[CVSize,CHSize]);
    
    %cellSize = uint32(CVSize*CHSize);
    invalidsNum = uint32(sum(colsInvalid,1));
    sumDepth =  uint32(sum(colsDepth,1));
    cellSizes = uint32(sum(numelCell,1));
    iconData = min(254,bitshift(sumDepth.*dLUT(1+cellSizes-invalidsNum),-16));
    iconData( cellSizes - invalidsNum <= lowThrPxlNum ) = 255;
    iconData = reshape(iconData,ceil([double(size(R,1)-SkipV)/double(CVSize) double(size(R,2)-2*SkipH)/double(CHSize)]));
    viconData = reshape(cellSizes-invalidsNum,ceil([double(size(R,1)-SkipV)/double(CVSize) double(size(R,2)-2*SkipH)/double(CHSize)]));
    
    iconData = iconData(1:min(end,iconSize(1)),1:min(end,iconSize(2)));
    viconData = viconData(1:min(end,iconSize(1)),1:min(end,iconSize(2)));
    
    
    icn = zeros(iconSize);
    icn(1:size(iconData,1),1:size(iconData,2)) = iconData;
    
    
    vicn = zeros(iconSize);
    vicn(1:size(viconData,1),1:size(viconData,2)) = viconData;
    
    
    
end


function [ b ] = im2colDistinct( a,blk )
    padval = 0;
    [m,n] = size(a);
    mpad = rem(m,blk(1)); if mpad>0, mpad = blk(1)-mpad; end
    npad = rem(n,blk(2)); if npad>0, npad = blk(2)-npad; end
    aa = mkconstarray(class(a), padval, [m+mpad n+npad]);
    aa(1:m,1:n) = a;
    
    [m,n] = size(aa);
    mblocks = m/blk(1);
    nblocks = n/blk(2);
    
    b = mkconstarray(class(a), 0, [prod(blk) mblocks*nblocks]);
    x = mkconstarray(class(a), 0, [prod(blk) 1]);
    rows = 1:blk(1); cols = 1:blk(2);
    for i=0:mblocks-1,
        for j=0:nblocks-1,
            x(:) = aa(i*blk(1)+rows,j*blk(2)+cols);
            b(:,i+j*mblocks+1) = x;
        end
    end

end


function out = mkconstarray(class, value, size)
    %MKCONSTARRAY creates a constant array of a specified numeric class.
    %   A = MKCONSTARRAY(CLASS, VALUE, SIZE) creates a constant array
    %   of value VALUE and of size SIZE.
    
    %   Copyright 1993-2013 The MathWorks, Inc.
    
    out = repmat(feval(class, value), size);
end

