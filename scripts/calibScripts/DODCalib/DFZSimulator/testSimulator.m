clear
fw = Pipe.loadFirmware('C:\source\algo_ivcam2\+Calibration\initScript');
changedregs.FRMW.gaurdBandV = single(0);
changedregs.DEST.baseline = single(30);
fw.setRegs(changedregs,'');
[regs,luts] = fw.get();

CBParams.size = 30;
CBParams.bsz = [9,13];
dist = 500;
[rpt,cbxyz] = simulateCB(dist,regs,CBParams);
[outregs,minerr,eFit]=calibDFZFromRPT(rpt,regs,1,0);
% The error when there is no noise is 0.04!!!
% After optimization we get to 0.01, which is not 0.
% It is interesting to find the source of the error. 

% Option 1 - getTrigo function is too crude. 
% I shall take the rpt, calculate the points using getTrigo and see the
% difference.
[xF,yF]=Calibration.aux.ang2xySF(rpt(:,:,2),rpt(:,:,3),regs,true);
xF = xF*double((regs.FRMW.xres-1))/double(regs.FRMW.xres);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
yF = yF*double((regs.FRMW.yres-1))/double(regs.FRMW.yres);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
rtd_= rpt(:,:,1)-regs.DEST.txFRQpd(1);
    
[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xF,yF,regs);
r = (0.5*(rtd_.^2 - regs.DEST.baseline2))./(rtd_ - regs.DEST.baseline.*sing);
    
z = r.*cosw.*cosx;
x = r.*cosw.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);
norm(v(:)-cbxyz(:))

% Straight forward - skipping the image plane
xyzn = ang2vec(rpt(:,:,2),rpt(:,:,3),regs);
cbr = sqrt(sum(cbxyz.^2,3));
xyz = normr(xyzn).*repmat(cbr(:),1,3);
Calibration.aux.evalGeometricDistortion(reshape(xyz,9,13,3),1)

% The problem seems to be: going to image plane and back to 3D.
% My primary suspect is the sing. I shall calculate the sing directly and
% from xF,yF and see if it is the same.
singAcc = cbxyz(:,:,1)./sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,2).^2+cbxyz(:,:,3).^2);
tabplot; imagesc(sing,[-0.4,0.4]),colorbar;
tabplot; imagesc(singAcc,[-0.4,0.4]),colorbar;
tabplot; imagesc(singAcc-sing),colorbar;


% I shall check the angles of get trigo.
% tanx should be linear with the pixel index.
tanxAcc = cbxyz(:,:,1)./cbxyz(:,:,3);
tanx = sinx./cosx;
tabplot; imagesc(tanxAcc,[-0.4,0.4]),colorbar;
tabplot; imagesc(tanx,[-0.4,0.4]),colorbar;
tabplot; plot(tanxAcc(7,:)),hold on , plot(tanx(7,:))
tabplot; plot(tanxAcc(7,:)-tanx(7,:))

acc = cbxyz(:,:,1)./sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,3).^2);
trig = sinx;
tabplot; imagesc(acc,[-0.4,0.4]),colorbar;
tabplot; imagesc(trig,[-0.4,0.4]),colorbar;
tabplot; plot(acc(7,:)),hold on , plot(trig(7,:))
tabplot; plot(acc(7,:)-trig(7,:))

acc = cbxyz(:,:,1)./sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,3).^2);
trig = sinx;
tabplot; imagesc(acc,[-0.4,0.4]),colorbar;
tabplot; imagesc(trig,[-0.4,0.4]),colorbar;
tabplot; plot(acc(7,:)),hold on , plot(trig(7,:))
tabplot; plot(acc(7,:)-trig(7,:))


% Check w
acc = sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,3).^2)./sqrt(cbxyz(:,:,1).^2+cbxyz(:,:,2).^2+cbxyz(:,:,3).^2);
trig = cosw;
tabplot; imagesc(acc,[-0.4,0.4]),colorbar;
tabplot; imagesc(trig,[-0.4,0.4]),colorbar;
tabplot; plot(acc(7,:)),hold on , plot(trig(7,:))
tabplot; plot(acc(7,:)-trig(7,:))