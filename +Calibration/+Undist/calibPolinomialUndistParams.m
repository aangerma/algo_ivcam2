function [ abest, meanerr] = calibPolinomialUndistParams( darr,regs,calibParams,aEval )
    opt.maxIter = 100000;
    opt.OutputFcn = [];
    opt.TolFun = 1e-8;
    opt.TolX = 1e-8;
    opt.Display ='none';
    func = @(x,a) x/2047*a(1)+(x/2047).^2*a(2)+(x/2047).^3*a(3);
    FE = [];
    if calibParams.fovExpander.valid
        FE = calibParams.fovExpander.table;
    end
    optFunc = @(a) (errFunc(darr,regs,a,func,FE,0));
    if exist('aEval','var')
        abest = aEval;
        [meanerr,errors]=errFunc(darr,regs,abest,func,FE,0);
        %
        %     for i = 1:numel(darr)
        %        dUndist(i) = darr(i);
        %        dUndist(i).rpt(:,:,2) = darr(i).rpt(:,:,2)+func(darr(i).rpt(:,:,2),abest);
        %     end
        
        return
    end
    a0 = double([0,0,0]);
    [meanerr,errors]=errFunc(darr,regs,a0,func,FE,0);
    abest = fminsearch(@(a) optFunc(a),a0,opt);
    abest = fminsearch(@(a) optFunc(a),abest,opt);
    [meanerr,errors]=errFunc(darr,regs,abest,func,FE,0);
    %
    % for i = 1:numel(darr)
    %    dUndist(i) = darr(i);
    %    dUndist(i).rpt(:,:,2) = darr(i).rpt(:,:,2)+func(darr(i).rpt(:,:,2),abest);
    % end
    
end


function [e,eAll]=errFunc(darr,regs,a,func,FE,verbose)
    if ~exist('verbose','var')
        verbose = 0;
    end
    e = [];
    eFit = [];
    for i = 1:numel(darr)
        d = darr(i);
        vUnit = Calibration.aux.ang2vec(d.rpt(:,2)+func(d.rpt(:,2),a),d.rpt(:,3),regs,FE)';
        % Update scale to take margins into acount.
         sing = vUnit(:,1);
        rtd_=d.rpt(:,1)-regs.DEST.txFRQpd(1);
        r = (0.5*(rtd_.^2 - regs.DEST.baseline2))./(rtd_ - regs.DEST.baseline.*sing);
        v = vUnit.*r;
        numVert = d.grid(1)*d.grid(2);
        numPlanes = d.grid(3);
        for pid = 1:numPlanes
            idxs = (pid-1)*numVert+1:pid*numVert;
            vPlane  = v(idxs,:);
            refPlane = d.pts3d(idxs,:);
            isValid = ~isnan(vPlane(:,1));
            [e(end+1),eFit(end+1)]=Calibration.aux.evalGeometricDistortion(vPlane(isValid,:),refPlane(isValid,:),verbose);
        end
    end
    eAll = e;
    e = mean(e);
end