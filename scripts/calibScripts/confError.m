
%%
ivsfn='D:\data\ivcam20\exp\20171204\5\rec_0001.ivs';
p=Pipe.autopipe(ivsfn,'verbose',false,'saveresults',false,'viewResults',false);
%%
% pts=detectCheckerboardPoints(p.iImg);
% K=convhull(pts(:,1),pts(:,2));
% msk=poly2mask(pts(K,1),pts(K,2),size(p.iImg,1),size(p.iImg,2));
load dbg
[~,d] = planeFitRansac(p.vImg(:,:,1),p.vImg(:,:,2),p.vImg(:,:,3),msk);
d = abs(d);
d=min(d,8);
cgt=floor(d/8)
% imagesc(d)

