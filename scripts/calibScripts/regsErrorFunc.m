function e = regsErrorFunc(p)

%%
newregs.MTLB.fastChDelay=uint32(p);

ivsfn='D:\data\ivcam20\exp\20171204\5\rec_0001.ivs';
calibfn=[fileparts(ivsfn) '\calib.csv'];

calibtmp=[tempname '.csv'];
copyfile(calibfn,calibtmp);
fw=Firmware;
fw.setRegs(calibtmp)
fw.setRegs(newregs,calibtmp);
fw.writeUpdated(calibtmp);
p=Pipe.autopipe(ivsfn,'verbose',false,'saveresults',false,'viewResults',false,'calibfile',calibtmp);
%%
% pts=detectCheckerboardPoints(p.iImg);
% K=convhull(pts(:,1),pts(:,2));
% msk=poly2mask(pts(K,1),pts(K,2),size(p.iImg,1),size(p.iImg,2));
load dbg
rng(1)
[~,d] = planeFitRansac(p.vImg(:,:,1),p.vImg(:,:,2),p.vImg(:,:,3),msk);
d(~msk)=nan;
e=rms(d(~isnan(d)));
% imagesc(d)

