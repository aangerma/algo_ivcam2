function [outregs,minerr,darr]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.
par = calibParams.dfz;
FE = [];
mode=regs.FRMW.mirrorMovmentMode;
xfov=regs.FRMW.xfov(mode);
yfov=regs.FRMW.yfov(mode);

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
    x0 = double([xfov yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV regs.FRMW.polyVars]);    
end

    %%
    xL = [par.fovxRange(1) par.fovyRange(1) par.delayRange(1) par.zenithxRange(1) par.zenithyRange(1) 0 0 0];
    xH = [par.fovxRange(2) par.fovyRange(2) par.delayRange(2) par.zenithxRange(2) par.zenithyRange(2) 0 0 0];
    regs = x2regs(x0,regs);
    undistFunc = @(ax,polyVars) ax + ax/2047*polyVars(1)+(ax/2047).^2*polyVars(2)+(ax/2047).^3*polyVars(3);
    if iseval
        
        [minerr,~,darr.vCalibDfz]=errFunc(darr,regs,x0,undistFunc,FE,0);
        outregs = [];
        return
    end
    [e,eFit]=errFunc(darr,regs,x0,undistFunc,FE,1);
    printErrAndX(x0,e,eFit,'X0:',verbose)
    
    % Define optimization settings
    opt.maxIter = 10000;
    opt.OutputFcn = [];
    opt.TolFun = 1e-6;
    opt.TolX = 1e-6;
    opt.Display ='none';
    
    optFunc = @(x) (errFunc(darr,regs,x,undistFunc,FE,1) + par.zenithNormW * zenithNorm(regs,x));
    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerrPreUndist,eFit]=errFunc(darr,outregs,xbest,undistFunc,FE,1);
    % Optimize Undist poly params
    optFunc = @(x) (errFunc(darr,regs,x,undistFunc,FE,0));
    
    x0 = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1) outregs.FRMW.laserangleH outregs.FRMW.laserangleV outregs.FRMW.polyVars]);    
    xL = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1) outregs.FRMW.laserangleH outregs.FRMW.laserangleV par.polyVarRange(1,:)]);    
    xH = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1) outregs.FRMW.laserangleH outregs.FRMW.laserangleV par.polyVarRange(2,:)]);    

    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerr,eFit]=errFunc(darr,outregs,xbest,undistFunc,FE,0);
    
    printErrAndX(xbest,minerr,eFit,'Xfinal:',verbose)
    outregs_full = outregs;
    outregs = x2regs(xbest);
    fprintff('DFZ result: fx=%.1f, fy=%.1f, dt=%4.0f, zx=%.2f, zy=%.2f, eGeom=%.2f.\n',...
        outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV, minerrPreUndist);
    fprintff('Undist result: polyVars=[%.2f,%.2f,%.2f], eGeom=%.2f.\n',...
         xbest(6),xbest(7),xbest(8),minerr);
    
    
    printPlaneAng(darr,outregs_full,xbest,undistFunc,FE,fprintff,0);
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

function [e,eFit,v]=errFunc(darr,rtlRegs,X,undistFunc,FE,useCropped)
    %build registers array
    % X(3) = 4981;
    rtlRegs = x2regs(X,rtlRegs);
    e = [];
    eFit = [];
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
        else
            grid = d.grid;
        end
        v = calcVerices(d,X,rtlRegs,undistFunc,FE,useCropped);
        numVert = grid(1)*grid(2);
        numPlanes = grid(3);
        for pid = 1:numPlanes
            idxs = (pid-1)*numVert+1:pid*numVert;
            vPlane  = v(idxs,:);
            refPlane = d.pts3d(idxs,:);
            isValid = ~isnan(vPlane(:,1));
            [e(end+1),eFit(end+1)]=Calibration.aux.evalGeometricDistortion(vPlane(isValid,:),refPlane(isValid,:),false);
        end
    end
    eFit = mean(eFit);
    e = mean(e);
end

function [v,x,y,z] = calcVerices(d,X,rtlRegs,undistFunc,FE,useCropped)
    if useCropped
        rpt = d.rptCropped;
    else
        rpt = d.rpt;
    end
    vUnit = Calibration.aux.ang2vec(undistFunc(rpt(:,2),[X(6),X(7),X(8)]),rpt(:,3),rtlRegs,FE)';
    %vUnit = reshape(vUnit',size(d.rpt));
    %vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    if rtlRegs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    rtd_=rpt(:,1)-rtlRegs.DEST.txFRQpd(1);
    r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    v = double(vUnit.*r);
    if nargout>1
        x = v(:,1);
        y = v(:,2);
        z = v(:,3);
    end
    
end

function [] = printPlaneAng(darr,rtlRegs,X,undistFunc,FE,fprintff,useCropped)
    rtlRegs = x2regs(X,rtlRegs);
    horizAng = zeros(1,numel(darr));
    verticalAngl = zeros(1,numel(darr));
    fprintff('                       Plane horizontal angle:       Plane Vertical angle:\n');
    
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
        else
            grid = d.grid;
        end
        [~,x,y,z] = calcVerices(d,X,rtlRegs,undistFunc,FE,useCropped);
        numVert = grid(1)*grid(2);
        numPlanes = grid(3);
        for pid=1:numPlanes
            idxs = [(pid-1)*numVert+1:pid*numVert]';
            isValid = ~isnan(x(idxs,:));
            idxs = idxs(isValid(:));
            A = [x(idxs) y(idxs) ones(size(idxs))*mean(z(idxs))];
            p = (A'*A)\(A'*z(idxs));
            horizAng(1,i) = 90-atan2d(p(3,:),p(1,:));
            verticalAngl(1,i) = 90-atan2d(p(3,:),p(2,:));
            fprintff('frame %3d plane %d:              %7.3g                          %7.3g         \n', i,pid, horizAng(i), verticalAngl(i));
        end
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
    iterRegs.FRMW.projectionYshear(i)=single(0);
end
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));
iterRegs.FRMW.polyVars =single([x(6),x(7),x(8)]);
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
