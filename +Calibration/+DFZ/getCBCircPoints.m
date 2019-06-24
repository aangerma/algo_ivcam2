function pCirc = getCBCircPoints(pts,grid) 
    
h = grid(1);
w = grid(2);
pts = reshape(pts,[h,w,2]);

valid = ~isnan(pts(:,:,1));
[firstR,firstC] = find(valid,1);
h = sum(sum(valid,2)>0);
w = sum(sum(valid,1)>0);
pts = pts(firstR:firstR+h-1,firstC:firstC+w-1,:);
circumference = [ones(w,1),(1:w)';
    (1:h)',w*ones(h,1);
    h*ones(w,1),flipud((1:w)');
    flipud((1:h)'),ones(h,1)];
pCirc = cell2mat(arrayfun(@(n) squeeze(pts(circumference(n,1),circumference(n,2),:)),1:size(circumference,1),'UniformOutput',false))';


end
