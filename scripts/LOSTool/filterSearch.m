function filterSearch()
addpath('../POC4');
bd = 'd:\data\lidar\EXP\20171025\';
pbase = xml2structWrapper([bd 'pocConfigBase.xml']);

x0=p2x(pbase);
errFunc = @(x) calcLoss(bd,pbase,x);
[xbest,eB]=gradientDecent(x0,errFunc,'xEps',10,'xStep',2000,'xTol',50,'verbose',true);
disp(eB);
pnew=x2p(xbest,pbase);
struct2xmlWrapper(pnew,[bd 'pocConfigBest.xml']);



end

function x=p2x(p)
x = [vec(p.fa.filt');vec(p.sa.filt');vec(p.pa.filt')];
end

function p=x2p(x,pbase)
        p=pbase;
        fafilt = reshape(x(1:4),2,2)';
        safilt = reshape(x(5:8),2,2)';
        pafilt = reshape(x(9:14),2,3)';
        p.fa.filt=fafilt;
        p.sa.filt=safilt;
        p.pa.filt=pafilt;
    end

function err=calcLoss(bd,pbase,x)
x = max(x,0);
pnew=x2p(x,pbase);

try
    warning off
    ivsarr=aux.runPOCanalyzer(bd,false,pnew);%generate ivs
    [errF, errSx, errSy] = losTool(ivsarr,false);
    err = mean([errF, errSx, errSy]);
    warning on
catch e,
    
    fprintf('ERROR:(%s)\n',e.message);
    err = inf;
end

    
end

