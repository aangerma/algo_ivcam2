function referenceOffset  = referenctOffsetCalibration(Ts,vFst,regs,tauGT)

prms = regs.gnr;
names = fieldnames(prms);
for i=1:length(names)
    prms.(names{i}) = double(prms.(names{i}));
end

Ts = 1/round(1/Ts);
N = prms.codeLength;
kerLen = N*prms.tx;
prms.ker = prms.txCode(end-N+1:end);
prms.ker(prms.ker==0) = -1;

kerLenTs = round(kerLen/Ts);
seq = reshape(vFst(1:floor(length(vFst)/kerLenTs)*kerLenTs),kerLenTs,[]);
ker = (reshape(repmat(prms.ker(:),1,1/Ts)',[],1));

cDp = (Utils.correlator((seq),ker));
pkmx = max(cDp);
pkmxThr = prctile(pkmx, 90);

% [y,x]=find(cDp>pkmxThr);
% ind = mean(y);
cDp(:,pkmx<pkmxThr)=[];
cDp=mean(cDp,2);
cThr = max(cDp)/2;
cext = crossing([],cDp,cThr);
if(length(cext)~=2)
    clf;
    plot(cDp);
    title('correlation')
    error('Bad correlation results- check if right kernel/kernel size OR fast channel should be upside-down');
end
if(diff(cext)>kerLenTs/2)
    cext(1)=cext(1)+kerLenTs;
end
ind =mean(cext); 


tau=(ind-1)*Ts;
referenceOffset = tau-tauGT;



tDisp = (0:length(cDp)-1)*Ts ;
txt = sprintf('offset: %f',referenceOffset);
figure(6536); clf;
plot(tDisp-referenceOffset,normByMax(cDp));
line([tauGT tauGT ],get(gca,'ylim'),'color','r')
title(txt)
drawnow;
referenceOffset = mod(referenceOffset+kerLen,kerLen);
disp(txt);
end
