function img=raw2img(ivs,s,sz)
if(length(ivs)~=1)
    img=cell(length(ivs),1);
    for i=1:length(ivs)
    img{i}=Utils.raw2img(ivs(i),s,sz);
    end
    return;
end

if(~exist('sz','var'))
    sz=[512 512];
end
xy = double(ivs.xy);
v = circshift(double(ivs.slow),s);
xy=round(((xy-min(xy,[],2))./(max(xy,[],2)-min(xy,[],2)).*(sz(:)-1))+1);

g = all(xy>0 & bsxfun(@le,xy,flipud(sz(:))) );

xy=xy(:,g);
v=v(g);

ind=sub2ind(sz,xy(2,:),xy(1,:));

img=accumarray(ind',v,[prod(sz) 1],@mean,nan);
img=reshape(img,sz);
end