function [outregs,minerr,irNew]=calibDFZ(d,regs,verbose)




if(~exist('verbose','var'))
    verbose=true;
end

%some filtering
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian_(imv(:,bd));

%calc RTD 
[v,r] = Pipe.z16toVerts(d.z,regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
% rtd=conv2(rtd,fspecial('gaussian',[10 10],5),'same');
rtd=rtd+regs.DEST.txFRQpd(1);
%calc angle
[yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
[angx,angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);

%verification
[~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
assert(max(vec(abs(xF-xg)))<0.1)
assert(max(vec(abs(yF-yg)))<0.1)



%find CB points
[p,bsz] = detectCheckerboardPoints(normByMax(im));
it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1));
%rtd,ohi,theta
rpt=cat(3,it(rtd),it(angx),it(angy));






opt.maxIter=1000;
opt.OutputFcn=[];
opt.TolFun =10;
opt.tolX=inf;
if(verbose)
    opt.Display='none';
end

x0 = double([regs.FRMW.xfov regs.FRMW.yfov 5000 regs.FRMW.laserangleH regs.FRMW.laserangleV]);
xL = [40 40 0   -3 -3];
xH = [90 90 20000   3  3];
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,verbose),x0,xL,xH,opt);

outregs.FRMW.xfov=single(xbest(1));
outregs.FRMW.yfov=single(xbest(2));
outregs.DEST.txFRQpd=[1 1 1]*single(xbest(3));

[~,~,xF,yF]=errFunc(cat(3,rtd,angx,angy),regs,xbest,false);
ok=~isnan(xF) & ~isnan(yF)  & d.i>1;
irNew=griddata(double(xF(ok)),double(yF(ok)),double(d.i(ok)),xg,yg);

end


function [e,v,xF,yF]=errFunc(rpt,rtlRegs,X,verbose)
%build registers array
iterRegs=x2regs([rtlRegs.GNRL.imgVsize rtlRegs.GNRL.imgHsize],X);
rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);



[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);


rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);


e=Calibration.aux.evalGeometricDistortion(v,verbose);
if(verbose)
fprintf('%f ',[X e]);
fprintf('\n');
end
drawnow;
end

function regs=x2regs(sz,x)
regs.FRMW.xfov=x(1);
regs.FRMW.yfov=x(2);
regs.FRMW.gaurdBandH=0;
regs.FRMW.gaurdBandV=0;
regs.FRMW.xres=sz(2);
regs.FRMW.yres=sz(1);
regs.FRMW.marginL=0;
regs.FRMW.marginT=0;

regs.FRMW.xoffset=0;
regs.FRMW.yoffset=0;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.DEST.txFRQpd=[1 1 1]*x(3);
regs.DIGG.undistBypass = false;
regs.FRMW.undistXfovFactor=1;
regs.FRMW.undistYfovFactor=1;
regs.GNRL.rangeFinder=false;


regs.FRMW.laserangleH=x(4);
regs.FRMW.laserangleV=x(5);
end