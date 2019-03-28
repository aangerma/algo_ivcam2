function [iShr] = shrinkScanlinesX(img)

iShr = zeros(size(img), class(img));

for (i=1:size(iShr,1))

    L = img(i,:);
    valids = find(L ~= 0);
    n = length(valids);
    iShr(i,1:n) = L(valids);
    
end

end


