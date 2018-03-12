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
%some filtering - remove NANS
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));

%calc RTD 
    % Get r from d.z
    if ~regs.DEST.depthAsRange
[~,r] = Pipe.z16toVerts(d.z,regs);
    else
        r = double(darr(i).z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
    end
    % get rtd from r
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;

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
    end
    warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
[p,bsz] = detectCheckerboardPoints(normByMax(im)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
%rtd,ohi,theta
rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
    darr(i).angx = angx;
    darr(i).angy = angy;
    darr(i).rtd = rtd;
    darr(i).valid = Calibration.aux.getProjectiveOutliers(regs,darr(i).rpt(:,:,2:3));
    
end
% Define optimization settings
% baseline, gaurdband, ... TODO: remove this line when the init script has
% baseline of 30. 
regs.DEST.baseline = single(30);
regs.DEST.baseline2 = single(single(regs.DEST.baseline).^2);

%%
x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV angXShift]);
xL = [40 40  -200     -3 -3 ];
xH = [90 90 6000    3  3  0];
regs = x2regs(x0,regs);
[e,eFit]=errFunc(rpt,regs,x0,0);


%%
iterLuts = luts;
    minerr = e;

for i=1:10
%converge to best fov+delay
[xbest,minerr]=fminsearchbnd(@(x) errFunc(stream.s,iterRegs,iterLuts,x,0),x0,xL,xH,opt);
%find error vector
[e,v,ve]=errFunc(stream.s,x2regs(xbest,regs),iterLuts,xbest,verbose);
v=reshape(v,[],3)';
ve=reshape(ve,[],3)';
%reduce error in r direction
n=normc(v);
ve_=ve-n.*sum(ve.*n);

%convert xyz2uv

s=reshape(stream.p,[],2);
xyz2uv=TPS(v',reshape(s,[],2));
d=xyz2uv.at((v-ve_)');


%d=generateLSH(reshape(permute(v-ve,[3 1 2]),3,[])',1)*(generateLSH(reshape(permute(v,[3 1 2]),3,[])',1)\s(:,1:2));
[udistLUTinc,uxg,uyg,undistx,undisty]=Calibration.aux.generateUndistTables(s',d',size(stream.ir));
% quiver(s(:,1),s(:,2),d(:,1)-s(:,1),d(:,2)-s(:,2),0)

iterLuts.FRMW.undistModel = typecast(typecast(iterLuts.FRMW.undistModel,'single')-typecast(udistLUTinc(:),'single'),'uint32');
[udistRegs,udistLuts] = Pipe.DIGG.FRMW.buildLensLUT(iterRegs,iterLuts);
iterRegs=Firmware.mergeRegs(iterRegs,udistRegs);
iterLuts=Firmware.mergeRegs(iterLuts,udistLuts);
if(verbose)
fprintf('#%02d (%5.3f,%5.3f) %5.3f (%+5.3f,%+5.3f) e_dfz=%5.3f[mm] e_undist=%5.3f[pix]\n',i,xbest,minerr,rms([undistx(:);undisty(:)]));
% [xq,yq]= ang2xyLocal(imdata.angx,imdata.angy,iterRegs,iterLuts);
% ok=~isnan(xq) & ~isnan(yq)  & imdata.i>1;
% warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
% irNew = griddata(double(xq(ok)),double(yq(ok)),double(imdata.i(ok)),xg,yg);
% imagesc(irNew);
    dnew =[];
end
end
% quiver3(v(:,:,1),v(:,:,2),v(:,:,3),ve(:,:,1),ve(:,:,2),ve(:,:,3))
% 
printErrAndX(xbest,minerr,'Xfinal:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),xbest,xL,xH,opt);
outregs = x2regs(xbest);
rpt_new = cat(3,it(rtd),it(angx+xbest(6)),it(angy));
[e,eFit]=errFunc(rpt_new,outregs,xbest,1);
%% Do it for each in array
if nargout > 3
    darrNew = darr;
    for i = 1:numel(darr)
[zNewVals,xF,yF]=rpt2z(cat(3,rtd,angx+xbest(6),angy),outregs);
end
ok=~isnan(xF) & ~isnan(yF)  & d.i>1;
dnew.z = griddata(double(xF(ok)),double(yF(ok)),double(zNewVals(ok)),xg,yg);
dnew.i = griddata(double(xF(ok)),double(yF(ok)),double(d.i(ok)),xg,yg);
% dnew.c = griddata(double(xF(ok)),double(yF(ok)),double(d.c(ok)),xg,yg);
    end
end

function [xq,yq]= ang2xyLocal(angx,angy,regs,luts)
[x_,y_]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
[x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,Logger(),[]);
% % % [xq,yq] = Pipe.DIGG.ranger(x, y, regs);
% % % yq = double(yq);
% % % xq=double(xq)/4;
shift=double(regs.DIGG.bitshift);
xq = double(x)/2^shift;
yq = double(y)/2^shift;
end
% function [z,xF,yF] = rpt2z(rpt,rtlRegs)
% 
% [~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);
% rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);
% r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
if rtlRegs.DEST.depthAsRange
    z = r;
else
% z = r.*cosw.*cosx;
end
% z = z * rtlRegs.GNRL.zNorm;
% end
function [e,eFit]=errFunc(rpt,rtlRegs,X,verbose)
%build registers array
% X(3) = 4981;
rtlRegs = x2regs(X,rtlRegs);
for i = 1:numel(darr)
    d = darr(i);
[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2)+X(6),rpt(:,:,3),rtlRegs,Logger(),[]);

rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xq,yq,rtlRegs);

    r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

    z = r.*cosw.*cosx;
    x = r.*cosy.*sinx;
    y = r.*sinw;
v=double(cat(3,x,y,z));


[e,eFit]=Calibration.aux.evalGeometricDistortion(v,verbose);
end
eFit = mean(eFit);
e = mean(e);
end
function printErrAndX(X,e,preSTR,verbose)
if verbose 
    fprintf('%-8s',preSTR);
    fprintf('% 4.2f ',X);
    fprintf('e: %.2f[mm] ',e);
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

iterRegs.FRMW.xres=rtlRegs.GNRL.imgHsize;
iterRegs.FRMW.yres=rtlRegs.GNRL.imgVsize;
iterRegs.FRMW.marginL=int16(0);
iterRegs.FRMW.marginT=int16(0);

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

function stream=getInputStream(d,regs,luts)


z=double(d.z)/2^double(regs.GNRL.zMaxSubMMExp);
z(z==0)=nan;
rv = z(Utils.indx2col(size(z),[3 3]));
z = reshape(nanmedian(rv),size(z));
 

sz = size(z);
[sinx,cosx,singy,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(sz,regs);%#ok

[yg,xg]=ndgrid(1:sz(1),1:sz(2));

if(regs.DEST.depthAsRange)
r=z;
else
r = z./(cosw.*cosx);
end
b = -2*r;
c = -double(2*r*regs.DEST.baseline.*sing + regs.DEST.baseline2);
stream.rtd = 0.5*(-b+sqrt(b.*b-4*c));
stream.rtd = stream.rtd+regs.DEST.txFRQpd(1);

if(regs.DIGG.sphericalEn)
yy = double(yg-1);
xx=double((xg-1)*4);
xx = xx-double(regs.DIGG.sphericalOffset(1));
yy = yy-double(regs.DIGG.sphericalOffset(2));
xx = xx*2^10;%bitshift(xx,+12-2);
yy = yy*2^12;%bitshift(yy,+12);
xx = xx/double(regs.DIGG.sphericalScale(1));
yy = yy/double(regs.DIGG.sphericalScale(2));

stream.angx = int32(xx);
stream.angy = int32(yy);
else
[stream.angx,stream.angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);
end
stream.ir = double(d.i);
ii = double(d.i);
ii(ii==0)=nan;
[p,bsz]=detectCheckerboardPoints(normByMax(ii));
it = @(k) interp2(xg,yg,double(k),reshape(p(:,1),bsz-1),reshape(p(:,2),bsz-1)); % Used to get depth and ir values at checkerboard locations.
stream.s = cat(3,it(stream.angx),it(stream.angy),it(stream.rtd),it(stream.ir));
stream.p=reshape(p,[bsz-1 2]);
%{
[xq,yq]= ang2xyLocal(stream.s(:,:,1),stream.s(:,:,2),regs,luts);
[sinx,cosx,singy,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(xq,yq,regs)
coswx=cosw.*cosx;
z = stream.s(:,:,3)/2.*coswx
%}
end
