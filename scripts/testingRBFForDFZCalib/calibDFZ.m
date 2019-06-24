function [outregs,minerr]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0,runParams)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.
global useOldCalib
useOldCalib = true;
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
if~exist('runParams','var') 
    runParams=[];
end
if(~exist('verbose','var')|| isempty(verbose))
    verbose=false;
end
if(~exist('fprintff','var')|| isempty(fprintff))
    fprintff=@(varargin) fprintf(varargin{:});
end
if(~exist('x0','var') || isempty(x0))% If x0 is not given, using the regs used i nthe recording
    if useOldCalib
    x0 = double([xfov yfov regs.DEST.txFRQpd(1) regs.FRMW.laserangleH regs.FRMW.laserangleV regs.FRMW.polyVars regs.FRMW.pitchFixFactor]);    
    else
    x0 = double([xfov, yfov, regs.DEST.txFRQpd(1), regs.FRMW.laserangleH, regs.FRMW.laserangleV,...
        regs.FRMW.undistAngHorz, regs.FRMW.undistAngVert, regs.FRMW.fovexRadialK, regs.FRMW.fovexTangentP, regs.FRMW.fovexCenter]);
    end
end

    %%
    if useOldCalib
    xL = [par.fovxRange(1) par.fovyRange(1) par.delayRange(1) par.zenithxRange(1) par.zenithyRange(1) 0 0 0 0 0 0 par.pitchFixFactorRange(1)];
    xH = [par.fovxRange(2) par.fovyRange(2) par.delayRange(2) par.zenithxRange(2) par.zenithyRange(2) 0 0 0 0 0 0 par.pitchFixFactorRange(2)];
    else
    xL = [par.fovxRange(1), par.fovyRange(1), par.delayRange(1), par.zenithxRange(1), par.zenithyRange(1),...
        par.undistHorzRange(1,:), par.undistVertRange(1,:), par.fovexRadialRange(1,:), par.fovexTangentRange(1,:), par.fovexCenterRange(1,:)];
    xH = [par.fovxRange(2), par.fovyRange(2), par.delayRange(2), par.zenithxRange(2), par.zenithyRange(2),...
        par.undistHorzRange(2,:), par.undistVertRange(2,:), par.fovexRadialRange(2,:), par.fovexTangentRange(2,:), par.fovexCenterRange(2,:)];
    % 6-11: quad undist x, 12-17: quad undist y, 18-20: rad fovex dist, 21-22: tang fovex dist, 23-24: fovex dist center
    xL([6:14,16:24]) = 0; % xL([8,10,12,13,15,17,18:24])=0; % xL(6:24) = 0; % xL([6:14,16:24]) = 0;
    xH([6:14,16:24]) = 0; % xH([8,10,12,13,15,17,18:24])=0; % xH(6:24) = 0; % xH([6:14,16:24]) = 0;
    end
    regs = x2regs(x0,regs);
    if iseval
        
        [minerr,~]=errFunc(darr,regs,x0,FE,0,runParams);
        outregs = [];
        return
    end
    [e,eFit]=errFunc(darr,regs,x0,FE,1);
    printErrAndX(x0,e,eFit,'X0:',verbose)
    
    % Define optimization settings
    opt.maxIter = 10000;
    opt.OutputFcn = [];
    opt.TolFun = 1e-6;
    opt.TolX = 1e-6;
    opt.Display ='none';
    
    optFunc = @(x) (errFunc(darr,regs,x,FE,1) + par.zenithNormW * zenithNorm(regs,x));
    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerrPreUndist,eFit]=errFunc(darr,outregs,xbest,FE,1);
    [minerrPreUndistFullImage,~]=errFunc(darr,outregs,xbest,FE,0);
    % Optimize Undist poly params
    optFunc = @(x) (errFunc(darr,regs,x,FE,0));
    
    if useOldCalib
    x0 = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1) outregs.FRMW.laserangleH outregs.FRMW.laserangleV outregs.FRMW.polyVars outregs.FRMW.pitchFixFactor]);
    xL = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1)-50 outregs.FRMW.laserangleH outregs.FRMW.laserangleV par.polyVarRange(1,:) outregs.FRMW.pitchFixFactor]);
    xH = double([outregs.FRMW.xfov(1) outregs.FRMW.yfov(1) outregs.DEST.txFRQpd(1)+50 outregs.FRMW.laserangleH outregs.FRMW.laserangleV par.polyVarRange(2,:) outregs.FRMW.pitchFixFactor]);
    else
    x0 = double([outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV,...
        outregs.FRMW.undistAngHorz, outregs.FRMW.undistAngVert, outregs.FRMW.fovexRadialK, outregs.FRMW.fovexTangentP, outregs.FRMW.fovexCenter]);
    xL = [outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV,...
        par.undistHorzRange(1,:), outregs.FRMW.undistAngVert, par.fovexRadialRange(1,:), par.fovexTangentRange(1,:), par.fovexCenterRange(1,:)];
    xH = [outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV,...
        par.undistHorzRange(2,:), outregs.FRMW.undistAngVert, par.fovexRadialRange(2,:), par.fovexTangentRange(2,:), par.fovexCenterRange(2,:)];
    % 6-11: quad undist x, 12-17: quad undist y, 18-20: rad fovex dist, 21-22: tang fovex dist, 23-24: fovex dist center
    xL([7:8,10:14,16:24]) = 0;
    xH([7:8,10:14,16:24]) = 0;
    end

    xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
    xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt);
    outregs = x2regs(xbest,regs);
    [minerr,eFit,eAll]=errFunc(darr,outregs,xbest,FE,0,runParams);
    
    printErrAndX(xbest,minerr,eFit,'Xfinal:',verbose)
    outregs_full = outregs;
    outregs = x2regs(xbest);
    fprintff('DFZ result: fx=%.1f, fy=%.1f, dt=%4.0f, zx=%.2f, zy=%.2f, eGeomCropped=%.2f, eGeomFull=%.2f, .\n',...
        outregs.FRMW.xfov(1), outregs.FRMW.yfov(1), outregs.DEST.txFRQpd(1), outregs.FRMW.laserangleH, outregs.FRMW.laserangleV, minerrPreUndist, minerrPreUndistFullImage);
    if useOldCalib
    fprintff('Undist result: polyVar=[%.2f,%.2f,%.2f], pitchFixFactor=%.2f, eGeomFull=%.2f.\n',...
         xbest(6),xbest(7),xbest(8),xbest(9),minerr);
    else
    fprintff('Quadratic undist result: hVec=[%.2f,%.2f,%.2f,%.2f,%.2f,%.2f], vVec=[%.2f,%.2f,%.2f,%.2f,%.2f,%.2f], eGeomFull=%.2f.\n',...
         xbest(6),xbest(7),xbest(8),xbest(9),xbest(10),xbest(11),xbest(12),xbest(13),xbest(14),xbest(15),xbest(16),xbest(17),minerr);
    fprintff('FOVex dist result: kVec=[%.2f,%.2f,%.2f], pVec=[%.2f,%.2f], center=[%.2f,%.2f], eGeomFull=%.2f.\n',...
         xbest(18),xbest(19),xbest(20),xbest(21),xbest(22),xbest(23),xbest(24),minerr);
    end
    
    printPlaneAng(darr,outregs_full,xbest,FE,fprintff,0,eAll);
    calcScaleError(darr,outregs_full,xbest,FE,fprintff,0,runParams);
    
    
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

function [e,eFit,eAll]=errFunc(darr,rtlRegs,X,FE,useCropped,runParams)
    %build registers array
    % X(3) = 4981;
    if ~exist('runParams','var')
        runParams = [];
    end
    rtlRegs = x2regs(X,rtlRegs);
    eAll = [];
    eFit = [];
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
        else
            grid = d.grid;
        end
        v = calcVerices(d,X,rtlRegs,FE,useCropped);
        numVert = grid(1)*grid(2);
        numPlanes = grid(3);
        for pid = 1:numPlanes
            idxs = (pid-1)*numVert+1:pid*numVert;
            vPlane  = v(idxs,:);
            refPlane = d.pts3d(idxs,:);
            isValid = ~isnan(vPlane(:,1));
            [eAll(end+1),eFit(end+1)]=Calibration.aux.evalGeometricDistortion(vPlane(isValid,:),refPlane(isValid,:),runParams);
            
            
        end
    end
    eFit = mean(eFit);
    e = mean(eAll);
end

function [v,x,y,z] = calcVerices(d,X,rtlRegs,FE,useCropped)
    global useOldCalib
    if useCropped
        rpt = d.rptCropped;
    else
        rpt = d.rpt;
    end
    if useOldCalib
    [angx,angy] = Calibration.Undist.applyPolyUndistAndPitchFix(rpt(:,2),rpt(:,3),rtlRegs);
    else
    [angx,angy] = Calibration.Undist.applyQuadraticUndist(rpt(:,2),rpt(:,3),rtlRegs);
    end
    vUnit = Calibration.aux.ang2vec(angx,angy,rtlRegs,FE)';
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
function [] = calcScaleError(darr,rtlRegs,X,FE,fprintff,useCropped,runParams)
    rtlRegs = x2regs(X,rtlRegs);
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
            pts = d.ptsCropped;
        else
            grid = d.grid;
            pts = d.pts;
        end
        v = calcVerices(d,X,rtlRegs,FE,useCropped);
        v = reshape(v,[grid(1:2),3]);
        v = Calibration.aux.CBTools.slimNans(v);
        pts = Calibration.aux.CBTools.slimNans(pts);
        ptx = pts(:,:,1);
        pty = pts(:,:,2);
        distX = sqrt(sum(diff(v,1,2).^2,3))/30-1;
        distY = sqrt(sum(diff(v,1,1).^2,3))/30-1;
        
        imSize  = fliplr(size(d.i));
        [yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);
        
        
        
        F = scatteredInterpolant(vec(ptx(1:end,1:end-1)),vec(pty(1:end,1:end-1)),vec(distX(1:end,:)), 'natural','none');
        scaleImX = F(xg, yg);
        F = scatteredInterpolant(vec(ptx(1:end-1,1:end)),vec(pty(1:end-1,1:end)),vec(distY(1:end,:)), 'natural','none');
        scaleImY = F(xg, yg);
        
        ff = Calibration.aux.invisibleFigure();
        subplot(121);
        imagesc(scaleImX);colormap jet;colorbar;
        title(sprintf('Scale Error X Image %d',i));        
        subplot(122);
        imagesc(scaleImY);colormap jet;colorbar;
        title(sprintf('Scale Error Y Image %d',i));        
        Calibration.aux.saveFigureAsImage(ff,runParams,'DFZ','ScaleErrorImage',1);
        
    end

end

function [] = printPlaneAng(darr,rtlRegs,X,FE,fprintff,useCropped,eAll)
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
        [~,x,y,z] = calcVerices(d,X,rtlRegs,FE,useCropped);
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
            fprintff('frame %3d plane %d:              %7.3g                          %7.3g              %7.3g\n', i,pid, horizAng(i), verticalAngl(i),eAll(i));
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
global useOldCalib
for(i=1:5)
    iterRegs.FRMW.xfov(i)=single(x(1));
    iterRegs.FRMW.yfov(i)=single(x(2));
    iterRegs.FRMW.projectionYshear(i)=single(0);
end
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));
if useOldCalib
iterRegs.FRMW.polyVars =single([x(6),x(7),x(8),x(9),x(10),x(11)]);
iterRegs.FRMW.polyVars =single([x(6),x(7),x(8),x(9),x(10),x(11)]);
iterRegs.FRMW.pitchFixFactor =single(x(9));
else
iterRegs.FRMW.undistAngHorz = single(x(6:11));
iterRegs.FRMW.undistAngVert = single(x(12:17));
iterRegs.FRMW.fovexRadialK = single(x(18:20));
iterRegs.FRMW.fovexTangentP = single(x(21:22));
iterRegs.FRMW.fovexCenter = single(x(23:24));
end
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
