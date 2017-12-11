
ir_delay  =[
    0    4
    512 0
    4095 0
    ];


x=linspace(0,4096,65);

lut=single(interp1(ir_delay(:,1),ir_delay(:,2),x,'cubic'));

plot(lut);
lut4regs = lut/1024;
% fprintf('DESTrxPWRpd_%03d h%08x\n',[0:64;typecast(lut4regs,'uint32')])
%%
newregs.DEST.rxPWRpd=lut4regs;
ivsfn='D:\data\ivcam20\exp\20171204\5\rec_0001.ivs';
calibfn=[fileparts(ivsfn) '\calib.csv'];
fw=Firmware;
fw.setRegs(calibfn)
fw.setRegs(newregs,calibfn);
fw.writeUpdated(calibfn);
p=Pipe.autopipe(ivsfn);
%%
pts=detectCheckerboardPoints(p.iImg);
K=convhull(pts(:,1),pts(:,2));
msk=poly2mask(pts(K,1),pts(K,2),size(p.iImg,1),size(p.iImg,2));
[m,d] = planeFitRansac(p.vImg(:,:,1),p.vImg(:,:,2),p.vImg(:,:,3),msk);
rms(d(~isnan(d)))
imagesc(d)

