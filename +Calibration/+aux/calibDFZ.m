function [outregs,results,allVertices]=calibDFZ(darr,regs,calibParams,fprintff,verbose,iseval,x0,runParams,tpsUndistModel)
% When eval == 1: Do not optimize, just evaluate. When it is not there,
% train.

%% Initializations
par = calibParams.dfz;
if ~regs.FRMW.fovexExistenceFlag % unit without FOVex
    par.fovexNominalRange = 0*par.fovexNominalRange;
    par.fovexRadialRange = 0*par.fovexRadialRange;
    par.fovexTangentRange = 0*par.fovexTangentRange;
    par.fovexCenterRange = 0*par.fovexCenterRange;
end
mode=regs.FRMW.mirrorMovmentMode;
xfov=regs.FRMW.xfov(mode);
yfov=regs.FRMW.yfov(mode);
if~exist('tpsUndistModel','var') 
    tpsUndistModel=[];
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
    x0 = double([xfov, yfov, regs.DEST.txFRQpd(1), regs.FRMW.laserangleH, regs.FRMW.laserangleV,...
        regs.FRMW.polyVars, regs.FRMW.pitchFixFactor, regs.FRMW.undistAngHorz, regs.FRMW.undistAngVert,...
        regs.FRMW.fovexNominal, regs.FRMW.fovexRadialK, regs.FRMW.fovexTangentP, regs.FRMW.fovexCenter]);
end

regs = x2regs(x0,regs);
doCrop = par.calibrateOnCropped;%calibrateOnCropped;
if iseval
    [geomErr,~,allVertices]=errFunc(darr,regs,x0,doCrop,runParams,tpsUndistModel);
    results.geomErr = geomErr;

    outregs = [];
    return
end

[e,eFit]=errFunc(darr,regs,x0,doCrop,[],tpsUndistModel);
printErrAndX(x0,e,eFit,'X0:',verbose)

%% Define optimization settings
opt.maxIter = 10000;
opt.OutputFcn = [];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display ='none';

optFunc = @(x) (errFunc(darr,regs,x,doCrop,[],tpsUndistModel)); % zenithNorm is omitted, hence zenithNormW is irrelevant

%% Optimize DFZ + coarse undist
optimizedParams = {'DFZ', 'coarseUndist'};
[xL, xH] = setLimitsPerParameterGroup(optimizedParams, regs, par);

xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
% xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt); % 2nd iteration (excessive?)
outregsPreUndist = x2regs(xbest,regs);
[minerrPreUndist, ~] = errFunc(darr,outregsPreUndist,xbest,doCrop,[],tpsUndistModel);

%% Optimize fine undist correction & FOVex parameters
x0 = double([outregsPreUndist.FRMW.xfov(1), outregsPreUndist.FRMW.yfov(1), outregsPreUndist.DEST.txFRQpd(1), outregsPreUndist.FRMW.laserangleH, outregsPreUndist.FRMW.laserangleV,...
    outregsPreUndist.FRMW.polyVars, outregsPreUndist.FRMW.pitchFixFactor, outregsPreUndist.FRMW.undistAngHorz, outregsPreUndist.FRMW.undistAngVert,...
    outregsPreUndist.FRMW.fovexNominal, outregsPreUndist.FRMW.fovexRadialK, outregsPreUndist.FRMW.fovexTangentP, outregsPreUndist.FRMW.fovexCenter]);
% optimizedParams = {'undistCorrHorz', 'undistCorrVert', 'fovexNominal', 'fovexLensDist'};
optimizedParams = {'undistCorrHorz', 'fovexLensDist'};
% optimizedParams = {'undistCorrHorz'};
[xL, xH] = setLimitsPerParameterGroup(optimizedParams, outregsPreUndist, par);

xbest = fminsearchbnd(@(x) optFunc(x),x0,xL,xH,opt);
% xbest = fminsearchbnd(@(x) optFunc(x),xbest,xL,xH,opt); % 2nd iteration (excessive?)
outregs = x2regs(xbest,regs);
[geomErr,eFit,allVertices,eAll] = errFunc(darr,outregs,xbest,doCrop,runParams,tpsUndistModel); % in debug mode, allVertices should be enabled inside errFunc
results.geomErr = geomErr;

printErrAndX(xbest,results.geomErr,eFit,'Xfinal:',verbose)
outregs_full = outregs;
outregs = x2regs(xbest);
printOptimResPerParameterGroup({'DFZ', 'coarseUndist'}, outregs, minerrPreUndist, fprintff)
printOptimResPerParameterGroup({'undistCorrHorz', 'undistCorrVert', 'fovexNominal', 'fovexLensDist'}, outregs, results.geomErr, fprintff)

printPlaneAng(darr,outregs_full,xbest,fprintff,0,eAll,tpsUndistModel);
% calcScaleError(darr,outregs_full,xbest,fprintff,0,runParams,tpsUndistModel);
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


function [e,eFit,allVertices,eAll]=errFunc(darr,rtlRegs,X,useCropped,runParams,tpsUndistModel)
    %build registers array
    % X(3) = 4981;
    if ~exist('runParams','var')
        runParams = [];
    end
    if ~exist('tpsUndistModel','var')
        tpsUndistModel = [];
    end
    rtlRegs = x2regs(X,rtlRegs);
    eAll = [];
    eFit = [];
    allVertices = {};
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
        else
            grid = d.grid;
        end
        v = calcVerices(d,X,rtlRegs,useCropped,tpsUndistModel);
        allVertices{i} = v; % DEBUG: enable only in debugging mode
        numVert = grid(1)*grid(2);
        numPlanes = grid(3);
        for pid = 1:numPlanes
            idxs = (pid-1)*numVert+1:pid*numVert;
            vPlane  = v(idxs,:);
            refPlane = d.pts3d(idxs,:);
            isValid = ~isnan(vPlane(:,1));
            [eAll(end+1),eFit(end+1)]=Calibration.aux.evalGeometricDistortion(vPlane(isValid,:),refPlane(isValid,:),runParams);
            
            
        end
        % allVertices{i} = v;
    end
    eFit = mean(eFit);
    e = mean(eAll);
end


function [v,x,y,z] = calcVerices(d,X,rtlRegs,useCropped,tpsUndistModel)
    if useCropped
        rpt = d.rptCropped;
    else
        rpt = d.rpt;
    end
    [angx,angy] = Calibration.Undist.applyPolyUndistAndPitchFix(rpt(:,2),rpt(:,3),rtlRegs);
    vUnit = Calibration.aux.ang2vec(angx,angy,rtlRegs)';
    vUnit = Calibration.Undist.undistByTPSModel( vUnit,tpsUndistModel);% 2D Undist - 

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


function [] = calcScaleError(darr,rtlRegs,X,fprintff,useCropped,runParams,tpsUndistModel)
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
        v = calcVerices(d,X,rtlRegs,useCropped,tpsUndistModel);
        v = reshape(v,[grid(1:2),3]);
        v = Calibration.aux.CBTools.slimNans(v);
        pts = Calibration.aux.CBTools.slimNans(pts);
        ptx = pts(:,:,1);
        pty = pts(:,:,2);
        distX = sqrt(sum(diff(v,1,2).^2,3))/30-1;
        distY = sqrt(sum(diff(v,1,1).^2,3))/30-1;
        
        imSize  = fliplr(size(d.i));
        [yg,xg]=ndgrid(0:imSize(2)-1,0:imSize(1)-1);
        
        xyDistX = [vec(ptx(1:end,1:end-1)),vec(pty(1:end,1:end-1)),vec(distX(1:end,:))];
        xyDistX = xyDistX(all(~isnan(xyDistX),2),:);
        F = scatteredInterpolant(xyDistX(:,1), xyDistX(:,2), xyDistX(:,3), 'natural','none');
        scaleImX = F(xg, yg);
        xyDistY = [vec(ptx(1:end-1,1:end)),vec(pty(1:end-1,1:end)),vec(distY(1:end,:))];
        xyDistY = xyDistY(all(~isnan(xyDistY),2),:);
        F = scatteredInterpolant(xyDistY(:,1), xyDistY(:,2), xyDistY(:,3), 'natural','none');
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


function [] = printPlaneAng(darr,rtlRegs,X,fprintff,useCropped,eAll,tpsUndistModel)
    rtlRegs = x2regs(X,rtlRegs);
    horizAng = zeros(1,numel(darr));
    verticalAngl = zeros(1,numel(darr));
    fprintff('                   Plane horizontal angle:   Plane Vertical angle: GID:\n');
    
    for i = 1:numel(darr)
        d = darr(i);
        if useCropped
            grid = d.gridCropped;
        else
            grid = d.grid;
        end
        [~,x,y,z] = calcVerices(d,X,rtlRegs,useCropped,tpsUndistModel);
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
            fprintff('frame %3d:       %7.3g              %7.3g             %7.3g\n', i, horizAng(i), verticalAngl(i),eAll(i));
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
iterRegs.FRMW.polyVars =single([x(6),x(7),x(8)]);
iterRegs.FRMW.pitchFixFactor =single(x(9));
iterRegs.FRMW.undistAngHorz = single(x(10:13));
iterRegs.FRMW.undistAngVert = single(x(14:17));
iterRegs.FRMW.fovexNominal = single(x(18:21));
iterRegs.FRMW.fovexRadialK = single(x(22:24));
iterRegs.FRMW.fovexTangentP = single(x(25:26));
iterRegs.FRMW.fovexCenter = single(x(27:28));
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


function [xL, xH] = setLimitsPerParameterGroup(optimizedParams, regs, par)
% set degenerate limits for fixed parameters
xL = single([regs.FRMW.xfov(1), regs.FRMW.yfov(1), regs.DEST.txFRQpd(1), regs.FRMW.laserangleH, regs.FRMW.laserangleV,...
    regs.FRMW.polyVars, regs.FRMW.pitchFixFactor, regs.FRMW.undistAngHorz, regs.FRMW.undistAngVert,...
    regs.FRMW.fovexNominal, regs.FRMW.fovexRadialK, regs.FRMW.fovexTangentP, regs.FRMW.fovexCenter]);
xH = xL;
% set desired limits for optimized parameters
for iParam = 1:length(optimizedParams)
    switch optimizedParams{iParam}
        case 'DFZ'
            xL(1:5) = [par.fovxRange(1), par.fovyRange(1), par.delayRange(1), par.zenithxRange(1), par.zenithyRange(1)];
            xH(1:5) = [par.fovxRange(2), par.fovyRange(2), par.delayRange(2), par.zenithxRange(2), par.zenithyRange(2)];
        case 'coarseUndist'
            xL(6:9) = [par.polyVarRange(1,:), par.pitchFixFactorRange(1)];
            xH(6:9) = [par.polyVarRange(2,:), par.pitchFixFactorRange(2)];
        case 'undistCorrHorz'
            xL(10:13) = par.undistHorzRange(1,:);
            xH(10:13) = par.undistHorzRange(2,:);
        case 'undistCorrVert'
            xL(14:17) = par.undistVertRange(1,:);
            xH(14:17) = par.undistVertRange(2,:);
        case 'fovexNominal'
            xL(18:21) = par.fovexNominalRange(1,:);
            xH(18:21) = par.fovexNominalRange(2,:);
        case 'fovexLensDist'
            xL(22:28) = [par.fovexRadialRange(1,:), par.fovexTangentRange(1,:), par.fovexCenterRange(1,:)];
            xH(22:28) = [par.fovexRadialRange(2,:), par.fovexTangentRange(2,:), par.fovexCenterRange(2,:)];
    end
end
end


function printOptimResPerParameterGroup(optimizedParams, regs, err, fprintff)
for iParam = 1:length(optimizedParams)
    switch optimizedParams{iParam}
        case 'DFZ'
            fprintff('Delay/Fov/Zenith: fx=%.2f, fy=%.2f, dt=%.2f, zx=%.2f, zy=%.2f.\n',...
                regs.FRMW.xfov(1), regs.FRMW.yfov(1), regs.DEST.txFRQpd(1), regs.FRMW.laserangleH, regs.FRMW.laserangleV)
        case 'coarseUndist'
            fprintff('Coarse undistort: polyVar=%.2f, pitchFixFactor=%.2f.\n',...
                regs.FRMW.polyVars(2), regs.FRMW.pitchFixFactor);
        case 'undistCorrHorz'
            fprintff('Fine undist horz: xCoef=[%.2f,%.2f,%.2f,%.2f].\n',...
                regs.FRMW.undistAngHorz(1), regs.FRMW.undistAngHorz(2), regs.FRMW.undistAngHorz(3), regs.FRMW.undistAngHorz(4));
        case 'undistCorrVert'
            fprintff('Fine undist vert: yCoef=[%.2f,%.2f,%.2f,%.2f].\n',...
                regs.FRMW.undistAngVert(1), regs.FRMW.undistAngVert(2), regs.FRMW.undistAngVert(3), regs.FRMW.undistAngVert(4));
        case 'fovexNominal'
            fprintff('FOVex expansion : nominalCoef=[%.2f,%.2f,%.2f,%.2f].\n',...
                regs.FRMW.fovexNominal(1), regs.FRMW.fovexNominal(2), regs.FRMW.fovexNominal(3), regs.FRMW.fovexNominal(4));
        case 'fovexLensDist'
            fprintff('FOVex distortion: kVec=[%.2f,%.2f,%.2f], pVec=[%.2f,%.2f], center=[%.2f,%.2f].\n',...
                regs.FRMW.fovexRadialK(1), regs.FRMW.fovexRadialK(2), regs.FRMW.fovexRadialK(3),...
                regs.FRMW.fovexTangentP(1), regs.FRMW.fovexTangentP(2), regs.FRMW.fovexCenter(1), regs.FRMW.fovexCenter(2));
    end
end
fprintff('--> eGeom=%.2f.\n', err)
end
