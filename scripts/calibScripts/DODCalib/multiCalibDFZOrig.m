function [outregs,minerr,eFit,darrNew]=multiCalibDFZOrig(darr,regs,verbose,eval,x0)
if(~exist('eval','var'))
    eval=false;
end
if(~exist('verbose','var'))
    verbose=true;
end 
if(~exist('x0','var'))
    x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV]);
end 
warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
for i = 1:numel(darr)
    
    if ~regs.DEST.depthAsRange
        [~,r] = Pipe.z16toVerts(darr(i).z,regs);
    else
        r = double(darr(i).z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
    end

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


    

    %xy2ang verification
    % [~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
    % assert(max(vec(abs(xF-xg)))<0.1,'xy2ang invertion error')
    % assert(max(vec(abs(yF-yg)))<0.1,'xy2ang invertion error')

    %find CB points
    [p,bsz] = detectCheckerboardPoints(normByMax(darr(i).i)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
%     if size(p,1) > 150
%         p = reshape(p,[bsz-1,2]);
%         p = (p(1:end-1,1:end-1,:)+p(2:end,2:end,:))*0.5;
%         it = @(k) interp2(xg,yg,k,p(:,:,1),p(:,:,2)); % Used to get depth and ir values at checkerboard locations.
%     else
    it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.
%     end
    
    
    
    %rtd,phi,theta
    darr(i).rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    darr(i).angx = angx;
    darr(i).angy = angy;
    darr(i).rtd = rtd;
    
    % From white squares
    % 1. find corners, get z at corners, from it calculate the R and RTD. And then feed to the optimization. 
%     assert(~regs.DIGG.sphericalEn);
%     regs.DEST.depthAsRange = 0;
%     [z,~,~,~]=Pipe.DEST.rtd2depth(rtd-regs.DEST.txFRQpd(1),regs);
%     regs.DEST.depthAsRange = 1;
%     itFromWhiteSquares = @(k) interpFromWhite(darr(i).i,k,1/8);
%     
%     [~,cosx,~,~,~,cosw,sing]=Pipe.DEST.getTrigo(size(z),regs);
%     zCB = itFromWhiteSquares(z);
%     rCB = zCB./(it(cosx).*it(cosw));
%     C=2*rCB*regs.DEST.baseline.*it(sing)- regs.DEST.baseline2;
%     rtd=rCB+sqrt(rCB.^2-C);
%     rtd=rtd+regs.DEST.txFRQpd(1);
%     darr(i).rpt=cat(3,rtd,it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

end
% calc the delay by optimization:




% Only from here we can change params that affects the 3D calculation (like
% baseline, guardband, ...
regs.DEST.baseline = single(30);
regs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);

%%


% x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV 0 0]);
% x0 = double([63.02 60.18 5073.33 0.65 0.68 0 0 ]); %eGeom BL 40
% x0 = double([59.30 56.62 5014.69 0.77 0.78 -0.00 -0.00]); %efit BL 40
% x0 = double([62.66 59.85 5067.85 1.13 0.76 -0.00 -0.00]); %eGeom BL 30 from Corners
% x0 = double([63.43 60.62 5079.24 0.99 0.69 -0.00 -0.00]); %eGeom BL 30 from Corners (different starting point)
% x0 = double([64.89 62.13 5104.42 1.42 0.54 -0.00 -0.00]); %eGeom BL 30 from Corners Joined sizes
% x0 = double([62.75 59.89 5073.15 1.19 0.77 -0.00 -0.00]); % eGeom BL 30 from white
% x0 = double([62.88 60.34 5068.11 1.01 1.23 -0.00 -0.00]); % eGeom BL 30 from Corners from image 24 
% x0 = double([64.32 61.49 5081.62 2.15 0.36 0 0]); % eGeom BL 30 from Corners from training large images.
% x0 = double([64.68 61.84 5090.45 1.88 0.43 -17.32 -31.63 ]);
xL = [40 40 4000   -3 -3];
xH = [90 90 6000    3  3];
regs = x2regs(x0,regs);

if eval 
    [e,eFit]=errFunc(darr,regs,x0,verbose);
    outregs = [];
    minerr = e;
    return
end
[e,eFit]=errFunc(darr,regs,x0,0);
printErrAndX(x0,e,eFit,'X0:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-3;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(darr,regs,x,0),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(darr,regs,x,0),xbest,xL,xH,opt);
% [xbest,minerr]=fminsearch(@(x) errFunc(darr,regs,x,0),x0,opt);

outregs = x2regs(xbest,regs);
[e,eFit]=errFunc(darr,outregs,xbest,verbose);
printErrAndX(xbest,e,eFit,'Xfinal:',verbose)

%% Do it for each in array
if nargout > 3
    darrNew = darr;
    for i = 1:numel(darr)
        [zNewVals,xF,yF]=rpt2z(cat(3,darrNew(i).rtd,darrNew(i).angx,darrNew(i).angy),outregs);
        ok=~isnan(xF) & ~isnan(yF)  & darrNew(i).i>1;
        darrNew(i).z = griddata(double(xF(ok)),double(yF(ok)),double(zNewVals(ok)),xg,yg);
        darrNew(i).i = griddata(double(xF(ok)),double(yF(ok)),double(darrNew(i).i(ok)),xg,yg);
%         darrNew(i).c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);
    end
end
end


function [z,xF,yF] = rpt2z(rpt,rtlRegs)

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);
rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
[~,cosx,~,~,~,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);
r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
if rtlRegs.DEST.depthAsRange
    z = r;
else
    z = r.*cosw.*cosx;
end
z = z * rtlRegs.GNRL.zNorm;
end
function [e,eFit]=errFunc(darr,rtlRegs,X,verbose)
%build registers array

rtlRegs = x2regs(X,rtlRegs);
for i = 1:numel(darr)
    d = darr(i);
    [~,~,xF,yF]=Pipe.DIGG.ang2xy(d.rpt(:,:,2),d.rpt(:,:,3),rtlRegs,Logger(),[]);


    rtd_=d.rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


    [sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);

    r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

    z = r.*cosw.*cosx;
    x = r.*cosy.*sinx;
    y = r.*sinw;
    v=cat(3,x,y,z);


    [e(i),eFit(i)]=Calibration.aux.evalGeometricDistortion(v,d.sz,verbose);
    
end
tmp = eFit;
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
iterRegs.FRMW.xres=rtlRegs.GNRL.imgHsize;
iterRegs.FRMW.yres=rtlRegs.GNRL.imgVsize;
iterRegs.FRMW.marginL=int16(0);
iterRegs.FRMW.marginT=int16(0);

iterRegs.FRMW.xoffset=single(0);
iterRegs.FRMW.yoffset=single(0);
iterRegs.FRMW.undistXfovFactor=single(1);
iterRegs.FRMW.undistYfovFactor=single(1);
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.DIGG.undistBypass = false;
iterRegs.GNRL.rangeFinder=false;


iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));

rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
