clear;
fw=Firmware;
fw.setRegs('DESTbaseline',single(30))
regs=fw.get();
%%
N=30;
im={};rxy={};
for i=1:N
%%
targetVector = 500*normc([randn(2,1)*0.5;1]);
[im{i},rxy{i},k]=genImgs(regs,targetVector );
imagesc(im{i});axis image
imwrite(im{i},sprintf('%04d.png',i));
drawnow;
end