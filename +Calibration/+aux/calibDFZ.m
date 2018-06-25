function [outregs,minerr,eFit,darrNew]=calibDFZ(darr,regs,verbose,eval,x0)
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


for i = 1:numel(darr)
    % Get r from d.z
    if ~regs.DEST.depthAsRange
        [~,r] = Pipe.z16toVerts(darr(i).z,regs);
    else
        r = double(darr(i).z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
    end
    % get rtd from r
    [~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
    C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
    rtd=r+sqrt(r.^2-C);
    rtd=rtd+regs.DEST.txFRQpd(1);
    
    %calc angles per pixel
    [yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
    if(regs.DIGG.sphericalEn)
        yy = double(yg);
        xx = double((xg)*4);
        xx = xx-double(regs.DIGG.sphericalOffset(1));
        yy = yy-double(regs.DIGG.sphericalOffset(2));
        xx = xx*2^10;%bitshift(xx,+12-2);
        yy = yy*2^12;%bitshift(yy,+12);
        xx = xx/double(regs.DIGG.sphericalScale(1));
        yy = yy/double(regs.DIGG.sphericalScale(2));
        
        angx = single(xx);
        angy = single(yy);
    else
        [angx,angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);
    end
    
    %find CB points
    warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
    [p,bsz] = detectCheckerboardPoints(normByMax(darr(i).i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.
    
    %rtd,phi,theta
    darr(i).rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    darr(i).angx = angx;
    darr(i).angy = angy;
    darr(i).rtd = rtd;
    darr(i).valid = ones(size(Calibration.aux.getProjectiveOutliers(regs,darr(i).rpt(:,:,2:3))));
    
end

% % Only from here we can change params that affects the 3D calculation (like
% % baseline, guardband, ... TODO: remove this line when the init script has
% % baseline of 30.
% regs.DEST.baseline = single(30);
% regs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);

%%
xL = [40 40 4000   -3 -3];
xH = [90 90 6000    3  3];
regs = x2regs(x0,regs);
if eval
    [minerr,eFit]=errFunc(darr,regs,x0);
    outregs = [];
    darrNew = [];
    return
end
[e,eFit]=errFunc(darr,regs,x0);
printErrAndX(x0,e,eFit,'X0:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(darr,regs,x),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(darr,regs,x),xbest,xL,xH,opt);
outregs = x2regs(xbest,regs);
[e,eFit]=errFunc(darr,outregs,xbest);
printErrAndX(xbest,e,eFit,'Xfinal:',verbose)
outregs = x2regs(xbest);
%% Do it for each in array
% if nargout > 3
%     darrNew = darr;
%     for i = 1:numel(darr)
%         [zNewVals,xF,yF]=rpt2z(cat(3,darrNew(i).rtd,darrNew(i).angx,darrNew(i).angy),outregs);
%         ok=~isnan(xF) & ~isnan(yF)  & darrNew(i).i>1;
%         darrNew(i).z = griddata(double(xF(ok)),double(yF(ok)),double(zNewVals(ok)),xg,yg);
%         darrNew(i).i = griddata(double(xF(ok)),double(yF(ok)),double(darrNew(i).i(ok)),xg,yg);
%         %         darrNew(i).c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);
%     end
% end


end

% 
% function [z,xF,yF] = rpt2z(rpt,rtlRegs)
% % This function isn't very relevant after fixing the ang2xy bug.
% [xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);
% rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
% [~,cosx,~,~,~,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);
% r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
% if rtlRegs.DEST.depthAsRange
%     z = r;
% else
%     z = r.*cosw.*cosx;
% end
% z = z * rtlRegs.GNRL.zNorm;
% end
function [e,eFit]=errFunc(darr,rtlRegs,X)
%build registers array
% X(3) = 4981;
rtlRegs = x2regs(X,rtlRegs);
for i = 1:numel(darr)
    d = darr(i);
    [xF,yF]=Calibration.aux.ang2xySF(d.rpt(:,:,2),d.rpt(:,:,3),rtlRegs,true);
    xF = xF*double((rtlRegs.GNRL.imgHsize-1))/double(rtlRegs.GNRL.imgHsize);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
    yF = yF*double((rtlRegs.GNRL.imgVsize-1))/double(rtlRegs.GNRL.imgVsize);% Get trigo seems to map 0 to -fov/2 and res-1 to fov/2. While ang2xy returns a value between 0 and 640.
    
    rtd_=d.rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
    
    
    [sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xF,yF,rtlRegs);
    
    r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    
    z = r.*cosw.*cosx;
    x = r.*cosw.*sinx;
    y = r.*sinw;
    v=cat(3,x,y,z);
    
    
    [e(i),eFit(i)]=Calibration.aux.evalGeometricDistortion(v,false);
    
end
eFit = mean(eFit);
e = mean(e);

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
