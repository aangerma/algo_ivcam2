function rgb=matmap2rgb(mat,map,p)
if(~exist('p','var'))
    p=[0 100];
end

mat = round(normByMax(double(mat),p)*(size(map,1)-1)+1);
map=permute(map,[1 3 2]);
rgb=reshape(map(mat(:),:),[size(mat) 3]);
end