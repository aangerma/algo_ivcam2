function [ abest, meanerr] = calibPolinomialUndistParams( darr,regs,calibParams,aEval )
opt.maxIter = 100000;
opt.OutputFcn = [];
opt.TolFun = 1e-8;
opt.TolX = 1e-8;
opt.Display ='none';
func = @(x,a) x/2047*a(1)+(x/2047).^2*a(2)+(x/2047).^3*a(3);

optFunc = @(a) (errFunc(darr,regs,a,func,0,calibParams.gnrl.cbSquareSz));
if exist('aEval','var')
    abest = aEval;
    [meanerr,errors]=errFunc(darr,regs,abest,func,0,calibParams.gnrl.cbSquareSz);
%     
%     for i = 1:numel(darr)
%        dUndist(i) = darr(i);
%        dUndist(i).rpt(:,:,2) = darr(i).rpt(:,:,2)+func(darr(i).rpt(:,:,2),abest);
%     end
    
    return 
end
a0 = double([0,0,0]);
[meanerr,errors]=errFunc(darr,regs,a0,func,0,calibParams.gnrl.cbSquareSz);
abest = fminsearch(@(a) optFunc(a),a0,opt);
abest = fminsearch(@(a) optFunc(a),abest,opt);
[meanerr,errors]=errFunc(darr,regs,abest,func,0,calibParams.gnrl.cbSquareSz);
% 
% for i = 1:numel(darr)
%    dUndist(i) = darr(i);
%    dUndist(i).rpt(:,:,2) = darr(i).rpt(:,:,2)+func(darr(i).rpt(:,:,2),abest);
% end

end


function [e,eAll]=errFunc(darr,regs,a,func,verbose,squareSz)
    if ~exist('verbose','var')
        verbose = 0;
    end
    for i = 1:numel(darr)
        d = darr(i);
        vUnit = Calibration.aux.ang2vec(d.rpt(:,:,2)+func(d.rpt(:,:,2),a),d.rpt(:,:,3),regs,[]);
        vUnit = reshape(vUnit',size(d.rpt));
        vUnit(:,:,1) = vUnit(:,:,1);
        % Update scale to take margins into acount.
        sing = vUnit(:,:,1);
        rtd_=d.rpt(:,:,1)-regs.DEST.txFRQpd(1);
        r = (0.5*(rtd_.^2 - regs.DEST.baseline2))./(rtd_ - regs.DEST.baseline.*sing);
        v = vUnit.*r;
        e(i)=Calibration.aux.evalGeometricDistortion(v,verbose,squareSz);
    end
    eAll = e;
    e = mean(e);    
end


