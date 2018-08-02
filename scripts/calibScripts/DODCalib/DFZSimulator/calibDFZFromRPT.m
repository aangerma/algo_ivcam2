function [outregs,e]=calibDFZFromRPT(rpt,regs,verbose,eval,x0)
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


%%
xL = [40 40 4000   -3 -3];
xH = [90 90 6000    3  3];
regs = x2regs(x0,regs);
if eval
    [e]=errFunc(rpt,regs,x0);
    outregs = [];
    return
end
[e] = errFunc(rpt,regs,x0);
printErrAndX(x0,e,'X0:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(rpt,regs,x),x0,xL,xH,opt);
[xbest,~]=fminsearchbnd(@(x) errFunc(rpt,regs,x),xbest,xL,xH,opt);
outregs = x2regs(xbest,regs);
[e]=errFunc(rpt,outregs,xbest);
printErrAndX(xbest,e,'Xfinal:',verbose)
outregs = x2regs(xbest);



end

function [e]=errFunc(rpt,rtlRegs,X)
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
    
    
e = aErr(v);
    


end
function printErrAndX(X,e,preSTR,verbose)
if verbose
    fprintf('%-8s',preSTR);
    fprintf('%4.2f ',X);
    fprintf('eAlex: %.2f ',e);
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
rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
