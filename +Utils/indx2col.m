function indx = indx2col(sz,wsz)

indx = reshape(1:prod(sz),sz);
indx = pad_array(indx,(wsz-1)/2,'replicate','both'); %Algo\Common\image_utils
indx = im2col_(indx,wsz);

end


function b =im2col_(a,blk)

    [ma,na] = size(a);
    m = blk(1); n = blk(2);
    
    
    
    % Create Hankel-like indexing sub matrix.
    mc = blk(1); nc = ma-m+1; nn = na-n+1;
    cidx = (0:mc-1)'; ridx = 1:nc;
    t = cidx(:,ones(nc,1)) + ridx(ones(mc,1),:);    % Hankel Subscripts
    tt = zeros(mc*n,nc);
    rows = 1:mc;
    for i=0:n-1,
        tt(i*mc+rows,:) = t+ma*i;
    end
    ttt = zeros(mc*n,nc*nn);
    cols = 1:nc;
    for j=0:nn-1,
        ttt(:,j*nc+cols) = tt+ma*j;
    end
    
    % If a is a row vector, change it to a column vector. This change is
    % necessary when A is a row vector and [M N] = size(A).
   
%     a = a(:);
    b = a(ttt);
end

