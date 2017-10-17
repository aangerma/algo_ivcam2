clear;
w = 64;
h = 64;
sr=16;
C = Codes.propCode(8,1);
k=kron(C,ones(sr,1))>0;
pcktsPerCods=length(k)/64;
reppk= @(x) kron(x(:),ones(pcktsPerCods,1));
tau=(0:h-1)'.*ones(1,w);
slowGT = min(2^12-1,max(1,reshape(0:w*h-1,h,w)));
slow = slowGT;
[yg,xg]=ndgrid(0:h-1,0:w-1);
rtdGT = yg*single(Utils.dtnsec2rmm(1/sr)*2);
yg(:,2:2:end)=flipud(yg(:,2:2:end));
tau(:,2:2:end)=flipud(tau(:,2:2:end));
slow(:,2:2:end)=flipud(slow(:,2:2:end));
fast=bsxfun(@circshift,repmat(k,1,h,w),permute(tau,[3 1 2]));
n = w*h*pcktsPerCods;

f_ldon = ones(1,n);
f_txcs = zeros(1,n);f_txcs(1:pcktsPerCods*h:end)=1;
f_sndr = vec(ones(pcktsPerCods*h,1)*(1-(-1).^(1:w))/2)';

xy = [reppk(xg(:)) reppk(yg(:)-2)]';
ivs.slow = uint16(reppk(slow))';
ivs.xy = int16(xy.*[4;1]);
ivs.fast = fast(:)';
ivs.flags = uint8(f_ldon+2*f_txcs+4*f_sndr);

fw=Firmware;



%%
clear r;
r.MTLB.xyRasterInput=true;
r.FRMW.xres = uint16(w);
r.FRMW.yres = uint16(h-4);
r.FRMW.xfov = single(20);
r.FRMW.yfov = single(r.FRMW.xfov*h/w);
r.FRMW.cbufConstLUT =true;
r.RAST.biltBypass=true;
r.JFIL.bypass=true;
r.DIGG.notchBypass=true;
r.DIGG.gammaBypass=true;
[r.FRMW.txCode,r.GNRL.codeLength]=Utils.bin2uint32(C);

fw.setRegs(r,'config.csv');

[regs,luts]=fw.get();
p=Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
%%
errIR = abs(slowGT(3:end-2,:)-double(p.iImgRAW));
errRTD = abs(rtdGT(3:end-2,:)-p.rtdImg);

 figure(1);imagesc(errIR);colorbar;
 figure(2);imagesc(errRTD);colorbar;
%%

return
%%
io.writeIVS(ivs,'pipechk.ivs');

xyret = [int16(linspace(w-1,0,4*h*pcktsPerCods));xy(2,1:4*h*pcktsPerCods)];
xyret(1,:)=xyret(1,:)-w/2;
    
xy_ =[xy(:,end-w/2*h*pcktsPerCods+1:end) xyret xy xyret(:,1:2*h*pcktsPerCods+1)]; 
fid = fopen('pipechk.bin32','wb');

fwrite(fid,typecast(vec(single(xy_)),'uint8'));
fclose(fid);


fw.writeUpdated('config.csv');
