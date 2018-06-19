function [outregs,minerr,eFit]=calibDFZFromRPT(rpt,regs,verbose,eval,x0)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.


if(~exist('eval','var'))
    eval=false;
end
if(~exist('verbose','var'))
    verbose=true;
end
if(~exist('x0','var'))% If x0 is not given, using the regs used i nthe recording
    x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV]);
end


% % Only from here we can change params that affects the 3D calculation (like
% % baseline, gaurdband, ... TODO: remove this line when the init script has
% % baseline of 30.
% regs.DEST.baseline = single(30);
% regs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);

%%
xL = [40 40 4000   -3 -3];
xH = [90 90 6000    3  3];
regs = x2regs(x0,regs);
if eval
    [minerr,eFit]=errFunc(rpt,regs,x0);
    outregs = [];
    return
end
[e,eFit] = errFunc(rpt,regs,x0);
printErrAndX(x0,e,eFit,'X0:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(rpt,regs,x),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x),xbest,xL,xH,opt);
outregs = x2regs(xbest,regs);
[e,eFit]=errFunc(rpt,outregs,xbest);
printErrAndX(xbest,e,eFit,'Xfinal:',verbose)
outregs = x2regs(xbest);



end

function [e,eFit]=errFunc(rpt,rtlRegs,X)
%build registers array
rtlRegs = x2regs(X,rtlRegs);

[xF,yF]=Calibration.aux.ang2xySF(rpt(:,:,2),rpt(:,:,3),rtlRegs,true);
xF = xF*double((rtlRegs.FRMW.xres-1))/double(rtlRegs.FRMW.xres);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
yF = yF*double((rtlRegs.FRMW.yres-1))/double(rtlRegs.FRMW.yres);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
    
rtd_= rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
    
    
[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xF,yF,rtlRegs);
    
r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    
z = r.*cosw.*cosx;
x = r.*cosw.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);
    
    
[e,eFit]=Calibration.aux.evalGeometricDistortion(v,false);
    


end
function printErrAndX(X,e,eFit,preSTR,verbose)
if verbose
    fprintf('%-8s',preSTR);
    fprintf('%4.2f ',X);
    fprintf('eAlex: %.2f ',e);
    fprintf('eFit: %.2f ',eFit);
    fprintf('\n');
end
end
function rtlRegs = x2regs(x,rtlRegs)


iterRegs.FRMW.xfov=single(x(1));
iterRegs.FRMW.yfov=single(x(2));
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));
if(~exist('rtlRegs','var'))
    rtlRegs=iterRegs;
    return;
end
iterRegs.FRMW.xoffset=single(0);
iterRegs.FRMW.yoffset=single(0);
iterRegs.FRMW.undistXfovFactor=single(1);
iterRegs.FRMW.undistYfovFactor=single(1);

iterRegs.DIGG.undistBypass = false;
iterRegs.GNRL.rangeFinder=false;



rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
