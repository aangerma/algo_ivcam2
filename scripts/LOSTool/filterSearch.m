function filterSearch()
addpath('../POC4');
bd = 'd:\data\lidar\EXP\20171025\';
p = xml2structWrapper([bd 'pocConfigBase.xml']);

x0=p2x(p);
errFunc = @(x) calcLoss(bd,x);
[xbest,eB]=gradientDecent(x0,errFunc,'xStep',50,'xTol',50,'verbose',true);
disp(eB);
pnew=x2p(xbest,p);
struct2xmlWrapper(pnew,[bd 'pocConfigBest.xml']);

end

function err=calcLoss(bd,x)
x = max(x,0);
pold = xml2structWrapper([bd 'pocConfigBase.xml']);
pnew=x2p(x,pold);
struct2xmlWrapper(pnew,[bd 'pocConfig.xml']);
try
    warning off
    ivsarr=aux.runPOCanalyzer(bd,false);%generate ivs
    [errF, errSx, errSy] = losTool(ivsarr,false);
    err = mean([errF, errSx, errSy]);
    warning on
catch e,
    msgText = getReport(e);
    fprintf('ERROR: %s\n',msgText);
    err = inf;
end
end

function x=p2x(p)
x = [vec(p.fa.filt');vec(p.sa.filt');vec(p.pa.filt')];
end
function p=x2p(x,p)
fafilt = reshape(x(1:4),2,2)';
safilt = reshape(x(5:8),2,2)';
pafilt = reshape(x(9:14),2,3)';
p.fa.filt=fafilt;
p.sa.filt=safilt;
p.pa.filt=pafilt;


end