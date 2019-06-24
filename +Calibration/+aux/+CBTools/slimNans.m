function [ pts ] = slimNans( pts )

cols = find(any(~isnan(pts(:,:,1)),1));
rows = find(any(~isnan(pts(:,:,1)),2));
pts = pts(rows,cols,:);

end

