function [outregs,minerr,eFit,darrNew]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0,flipBaseline)
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
    if(isempty(x0))% If x0 is not given, using the regs used i nthe recording
        x0 = double([regs.FRMW.xfov regs.FRMW.yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV regs.FRMW.projectionYshear 0 0]);
    end
    
    
    %%
    if flipBaseline
       regs.DEST.baseline = - regs.DEST.baseline;
    end
    xL = [par.fovxRange(1) par.fovyRange(1) par.delayRange(1) par.zenithxRange(1) par.zenithyRange(1) par.projectionYshear(1) par.dsmXOffset(1) par.dsmYOffset(1)];
    xH = [par.fovxRange(2) par.fovyRange(2) par.delayRange(2) par.zenithxRange(2) par.zenithyRange(2) par.projectionYshear(2) par.dsmXOffset(2) par.dsmYOffset(2)];
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
    opt.maxIter = 10000;
    opt.OutputFcn = [];
    opt.TolFun = 1e-6;
    opt.TolX = 1e-6;
    opt.Display ='none';
    optFunc = @(x) (errFunc(darr,regs,x,FE) + par.zenithNormW * zenithNorm(regs,x));
    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerr,eFit]=errFunc(darr,outregs,xbest,FE);
    printErrAndX(xbest,minerr,eFit,'Xfinal:',verbose)
    outregs_full = outregs;
    outregs = x2regs(xbest);
    fprintff('DFZ result: fx=%.1f, fy=%.1f, dt=%4.0f, zx=%.2f, zy=%.2f, yShear=%.2f, xOff = %.2f, yOff = %.2f, eGeom=%.2f.\n',...
        outregs.FRMW.xfov, outregs.FRMW.yfov, outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV, outregs.FRMW.projectionYshear,xbest(7),xbest(8),minerr);
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

function [e,eFit]=errFunc(darr,rtlRegs,X,FE)
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
        
        [e(i),eFit(i)]=Calibration.aux.evalGeometricDistortion(v,false);
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
    
    
    iterRegs.FRMW.xfov=single(x(1));
    iterRegs.FRMW.yfov=single(x(2));
    iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
    iterRegs.FRMW.laserangleH=single(x(4));
    iterRegs.FRMW.laserangleV=single(x(5));
    iterRegs.FRMW.projectionYshear=single(x(6));
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
