function [outregs,minerr,dWithRpt]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.
par = calibParams.dfz;
FE = [];
mode=regs.FRMW.mirrorMovmentMode;
xfov=regs.FRMW.xfov(mode);
yfov=regs.FRMW.yfov(mode);
projectionYshear=regs.FRMW.projectionYshear(mode);

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
    x0 = double([xfov yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV projectionYshear 0 0]);
end

    if ~isfield(darr, 'rpt')
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
                [angx,angy]=Calibration.aux.xy2angSF(xg,yg,regs,0);
            end

            %find CB points
            warning('off','vision:calibrate:boardShouldBeAsymmetric') % Supress checkerboard warning
            [p,bsz] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(darr(i).i)), calibParams.gnrl.cbPtsSz); % p - 3 checkerboard points. bsz - checkerboard dimensions.
            
            if isempty(p)
                fprintff('Error: checkerboard not detected!');
            end
            it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz),reshape(p(:,2)-1,bsz)); % Used to get depth and ir values at checkerboard locations.

            %rtd,phi,theta
            darr(i).rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.
            
        end
    end
    dWithRpt = darr;% Use it later for undistort
    for i = 1:numel(darr)
        % Take the middle 9x13 sub checkerboard -> LOS reports seems solid
        % there
        h = 9;
        w = 13;
        darr(i).rpt = darr(i).rpt(1+floor((end-h)/2):h+floor((end-h)/2),1+floor((end-w)/2):w+floor((end-w)/2),:);
    end
    %%
    xL = [par.fovxRange(1) par.fovyRange(1) par.delayRange(1) par.zenithxRange(1) par.zenithyRange(1) par.projectionYshear(1) par.dsmXOffset(1) par.dsmYOffset(1)];
    xH = [par.fovxRange(2) par.fovyRange(2) par.delayRange(2) par.zenithxRange(2) par.zenithyRange(2) par.projectionYshear(2) par.dsmXOffset(2) par.dsmYOffset(2)];
    regs = x2regs(x0,regs);
    if iseval
        [minerr,~]=errFunc(darr,regs,x0,FE,calibParams.gnrl.cbSquareSz);
        outregs = [];
        return
    end
    [e,eFit]=errFunc(darr,regs,x0,FE,calibParams.gnrl.cbSquareSz);
    printErrAndX(x0,e,eFit,'X0:',verbose)
    
    % Define optimization settings
    opt.maxIter = 10000;
    opt.OutputFcn = [];
    opt.TolFun = 1e-6;
    opt.TolX = 1e-6;
    opt.Display ='none';
    optFunc = @(x) (errFunc(darr,regs,x,FE,calibParams.gnrl.cbSquareSz) + par.zenithNormW * zenithNorm(regs,x));
    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerr,eFit]=errFunc(darr,outregs,xbest,FE,calibParams.gnrl.cbSquareSz);
printErrAndX(xbest,minerr,eFit,'Xfinal:',verbose)
outregs_full = outregs;
outregs = x2regs(xbest);
fprintff('DFZ result: fx=%.1f, fy=%.1f, dt=%4.0f, zx=%.2f, zy=%.2f, yShear=%.2f, xOff = %.2f, yOff = %.2f, eGeom=%.2f.\n',...
    outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV, outregs.FRMW.projectionYshear(1),xbest(7),xbest(8),minerr);
printPlaneAng(darr,outregs_full,xbest,FE,fprintff);
outregs.EXTL.dsmXoffset = regs.EXTL.dsmXoffset+xbest(7)/regs.EXTL.dsmXscale;
outregs.EXTL.dsmYoffset = regs.EXTL.dsmYoffset+xbest(8)/regs.EXTL.dsmYscale;
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

function [e,eFit]=errFunc(darr,rtlRegs,X,FE,cbSquareSz)
%build registers array
% X(3) = 4981;
rtlRegs = x2regs(X,rtlRegs);
for i = 1:numel(darr)
    d = darr(i);
    vUnit = Calibration.aux.ang2vec(d.rpt(:,:,2)+X(7),d.rpt(:,:,3)+X(8),rtlRegs,FE);
    vUnit = reshape(vUnit',size(d.rpt));
    vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    sing = vUnit(:,:,1);
    rtd_=d.rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
    r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    v = vUnit.*r;
    
        [e(i),eFit(i)]=Calibration.aux.evalGeometricDistortion(v,false,cbSquareSz);
end
eFit = mean(eFit);
e = mean(e);
end

function [] = printPlaneAng(darr,rtlRegs,X,FE,fprintff)
rtlRegs = x2regs(X,rtlRegs);
horizAng = zeros(1,numel(darr));
verticalAngl = zeros(1,numel(darr));
fprintff('                       Plane horizontal angle:       Plane Vertical angle:\n');

for i = 1:numel(darr)
    d = darr(i);
    vUnit = Calibration.aux.ang2vec(d.rpt(:,:,2)+X(7),d.rpt(:,:,3)+X(8),rtlRegs,FE);
    vUnit = reshape(vUnit',size(d.rpt));
    vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    sing = vUnit(:,:,1);
    rtd_=d.rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);
    r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    v = vUnit.*r;
    x = reshape(v(:,:,1), size(v,1)*size(v,2), []);
    y = reshape(v(:,:,2), size(v,1)*size(v,2), []);
    z = reshape(v(:,:,3), size(v,1)*size(v,2), []);
    A = [x y ones(length(x),1)*mean(z)];
    p = (A'*A)\(A'*z);
    horizAng(1,i) = 90-atan2d(p(3,:),p(1,:));
    verticalAngl(1,i) = 90-atan2d(p(3,:),p(2,:));
    fprintff('frame number %3d:              %7.3g                          %7.3g         \n', i, horizAng(i), verticalAngl(i));
end
end


function [zNorm] = zenithNorm(regs,x)
rtlRegs = x2regs(x,regs);
zNorm = rtlRegs.FRMW.laserangleH.^2 + rtlRegs.FRMW.laserangleV.^2;
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

for(i=1:5)
    iterRegs.FRMW.xfov(i)=single(x(1));
    iterRegs.FRMW.yfov(i)=single(x(2));
    iterRegs.FRMW.projectionYshear(i)=single(x(6));
end
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
