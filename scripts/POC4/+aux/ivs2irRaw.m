function img=ivs2irRaw(ivs,d,sz,roi)
if(~exist('roi','var'))
    roi=[0 0 sz];
end

s = circshift(ivs.slow',[d 1]);

xyNrm = round(bsxfun(@times,double(ivs.xy)/2^12+.5,sz'-1)+1);
xyNrm = bsxfun(@minus,xyNrm,roi(1:2)');
g = all(xyNrm>0 & bsxfun(@le,xyNrm,roi(3:4)') );

xyNrm=xyNrm(:,g);
s=s(g);

ind=sub2ind(roi([4 3]),xyNrm(2,:),xyNrm(1,:));

img=accumarray(ind',s,[prod(roi(3:4)) 1],@mean);
img=reshape(img,roi([4 3]));
end