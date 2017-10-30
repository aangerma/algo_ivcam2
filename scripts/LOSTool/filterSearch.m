function filterSearch()
addpath('../POC4');
bd = 'd:\data\lidar\EXP\20171025\';
p = xml2structWrapper([bd 'pocConfigBase.xml']);
x0 = p2x(p);
xbest=fminsearch(@(x) calcLoss(bd,x),x0);
pnew=x2p(xbest,p);
struct2xmlWrapper(pnew,[bd 'pocConfigBest.xml']);

end

function err=calcLoss(bd,x)
pold = xml2structWrapper([bd 'pocConfigBase.xml']);
pnew=x2p(x,pold);
struct2xmlWrapper(pnew,[bd 'pocConfig.xml']);
try
    aux.runPOCanalyzer(bd,false);%generate ivs
    [errF, errSx, errSy] = losTool(bd);
    err = mean([errF, errSx, errSy]);
    fprintf('stepErr: %f\n',err);
catch e,
    msgText = getReport(e);
    fprintf('ERROR: %s\n',msgText);
    err = 10;
end
end

function x=p2x(p)
x= [p.fa.filt(:)' p.sa.filt(:)' p.pa.filt(:)'];
end
function p=x2p(x,p)
fafilt = reshape(x(1:4),2,2);
safilt = reshape(x(5:8),2,2);
pafilt = reshape(x(9:12),2,2);
p.fa.filt=fafilt;
p.sa.filt=safilt;
p.pa.filt=pafilt;


end