function [outregs,minerr,eFit,darrNew]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.
par = calibParams.dfz;
FE = [];
if calibParams.fovExpander.valid
    FE = calibParams.fovExpander.table;
end
if(~exist('iseval','var') || isempty(iseval))
    iseval=false;
end
if(~exist('verbose','var')|| isempty(verbose))
    verbose=false;
end
if(~exist('fprintff','var')|| isempty(fprintff))
    fprintff=@(varargin) fprintf(varargin{:});
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
    [p,bsz] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(darr(i).i)), [9,13]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    if isempty(p)
        fprintff('Error: checkerboard not detected!');
    end
    it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz),reshape(p(:,2)-1,bsz)); % Used to get depth and ir values at checkerboard locations.
    
    %rtd,phi,theta
    darr(i).rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

end

%%
xL = [par.fovxRange(1) par.fovyRange(1) par.delayRange(1) par.zenithxRange(1) par.zenithyRange(1)]; 
xH = [par.fovxRange(2) par.fovyRange(2) par.delayRange(2) par.zenithxRange(2) par.zenithyRange(2)]; 
regs = x2regs(x0,regs);
if iseval
    [minerr,eFit]=errFunc(darr,regs,x0,FE);
    outregs = [];
    darrNew = [];
    return
end
[e,eFit]=errFunc(darr,regs,x0,FE);
printErrAndX(x0,e,eFit,'X0:',verbose)

% Define optimization settings
opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
[xbest,~]=fminsearchbnd(@(x) errFunc(darr,regs,x,FE),x0,xL,xH,opt);
[xbest,minerr]=fminsearchbnd(@(x) errFunc(darr,regs,x,FE),xbest,xL,xH,opt);
outregs = x2regs(xbest,regs);
[e,eFit]=errFunc(darr,outregs,xbest,FE);
printErrAndX(xbest,e,eFit,'Xfinal:',verbose)
outregs = x2regs(xbest);
fprintff('DFZ result: fx=%.1f, fy=%.1f, dt=%4.0f, zx=%.2f, zy=%.2f , eGeom=%.2f.\n',...
    outregs.FRMW.xfov, outregs.FRMW.yfov, outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV,e);
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

function [e,eFit]=errFunc(darr,rtlRegs,X,FE)
%build registers array
% X(3) = 4981;
rtlRegs = x2regs(X,rtlRegs);
for i = 1:numel(darr)
    d = darr(i);
    vUnit = ang2vec(d.rpt(:,:,2),d.rpt(:,:,3),rtlRegs,FE);
    vUnit = reshape(vUnit',size(d.rpt));
    % Update scale to take margins into acount.
    sing = vUnit(:,:,1); 
    rtd_=d.rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
    r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    v = vUnit.*r;
    
    [e(i),eFit(i)]=Calibration.aux.evalGeometricDistortion(v,false);
end
eFit = mean(eFit);
e = mean(e);

end
function [oXYZ] = ang2vec(angxQin,angyQin,regs,fovExpander)
%% ----STAIGHT FORWARD------
angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';

laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));

angyQ=angyQin(:);angxQ =angxQin(:);
angx = single(angxQ)*angXfactor;
angy = single(angyQ)*angYfactor;
oXYZ = Calibration.aux.applyExpander(oXYZfunc(angles2xyz(angx,angy)),fovExpander);

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
