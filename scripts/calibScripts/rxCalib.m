

%%
newregs.DEST.rxPWRpd=single(zeros(1,65));
ivsfn='D:\data\ivcam20\exp\20171204\5\rec_0001.ivs';
calibfn=[fileparts(ivsfn) '\calib.csv'];
fw=Firmware;
fw.setRegs(calibfn)
fw.setRegs(newregs,calibfn);
fw.writeUpdated(calibfn);
p=Pipe.autopipe(ivsfn,'verbose',false,'saveresults',false,'viewResults',false);

 [pts,bsz]=detectCheckerboardPoints(p.iImg);

  K=convhull(pts(:,1),pts(:,2));
  p.msk=poly2mask(pts(K,1),pts(K,2),size(p.iImg,1),size(p.iImg,2));

%%

[pbest,f]=fminsearchbnd(@(x) rxErroFunc(x,p),[14 512 1],[-20 100 -10],[20 2048 10],struct('Display','iter','OutputFcn',[]));
rxErroFunc(pbest,p)
%%
