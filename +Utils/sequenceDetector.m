function stats = sequenceDetector(chA,fw,avraging,verbose,statsOutliers)

if(~exist('statsOutliers','var'))
    statsOutliers = 0.20;
end
regs = fw.getRegs();
fsRate = double(regs.GNRL.sampleRate);
% t = 0:Ts:(length(chA)-1)*Ts;

% txTimes = 0:properties.templateT:t(end)-properties.templateT;
n = floor(length(chA)/(64));%*regs.GNRL.sampleRate*regs.GNRL.tx));


updateregs.FRMW.xres = 1;
updateregs.FRMW.yres = floor(n*64/(fsRate*double(regs.GNRL.codeLength)*avraging));
updateregs.FRMW.yres = updateregs.FRMW.yres;%!!!VITALY CMA BUG
updateregs.FRMW.xoffset=0;
updateregs.FRMW.yoffset=0;
updateregs.FRMW.xfov=0;
updateregs.FRMW.yfov=0;
updateregs.DEST.txFRQpd_000=0;
updateregs.JFIL.bypass = true;
updateregs.MTLB.gengBypass=1;
fw.setRegs(updateregs,'struct');
regs = fw.getRegs();
luts = fw.getLuts();


ins.fast = vec(chA(end-n*64+1:end))';
ins.slow = uint16(2^6*ones(1,n));    %%%%%%%%%%%%% chB!!!!!!!!!!!!!!!

yrep = double(regs.GNRL.codeLength)/64*fsRate*avraging;
ins.xy = int16([zeros(1,n);ceil((1:n)/yrep)-1]);
ins.flags=uint8(ones(1,n));
ins.flags(1)=3;

res = Pipe.hwpipe(ins,regs,luts,Pipe.setDefaultMemoryLayout(),false,[]);






r =  double(res.rImg);
score = res.cImg;

r = r(1:end-3);%!!!!!!!VITALI BUG
score = score(1:end-3);





mnr = prctile(r,1-statsOutliers);

nInliers = round(length(r)*(1-statsOutliers));
[~,ix]=sort(r-mnr);
rinliers = r(ix(1:nInliers));

stats.std=std(rinliers);
stats.mean = mean(rinliers);



if(verbose>0)
    fprintf('%12s|%12s\n','center','fitScore');
    fprintf('%s\n',repmat([repmat('-',1,12),'+'],1,2));
             fprintf('%12g|%12g\n',[r double(score)]');
        
    
%     if(verbose>1)
%         ker = double(reshape(repmat(regs.GNRL.txCode(:)>0,1,regs.GNRL.sampleRate)',[],1));
%         txTimes = Utils.rmm2dtnsec(r);
%         s = buffer(chA,length(ker));
%         fullcor =  Utils.correlator(uint8(s),uint8(ker(:)));
%         pktimes = txTimes;
%         figure();
%         tcorr= (0:(size(fullcor,1)*size(fullcor,2))-1)'/fs;
%         
%         corsegTimes = bsxfun(@plus,bsxfun(@plus,double(offset(:)'),(0:size(corseg,1)-1)'),(0:size(corseg,2)-1)*cmalen)/fs;
%         
%         plot(tcorr,fullcor(:),'.-',corsegTimes,corseg,'g.-');
%         hold on
%         plot(pktimes,interp1(tcorr,double(fullcor(:)),pktimes),'g.','markersize',20);
%         hold off
%         line([txTimes;txTimes],get(gca,'ylim'),'color','r')
%         axis tight
%     end
    
    
end





end
