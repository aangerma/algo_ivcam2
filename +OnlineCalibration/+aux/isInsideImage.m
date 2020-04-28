function isInside = isInsideImage(xy,res)
    isInside = xy(:,1) >= 0 & ... 
               xy(:,1) <= res(2)-1 & ...
               xy(:,2) >= 0 & ... 
               xy(:,2) <= res(1)-1;
end