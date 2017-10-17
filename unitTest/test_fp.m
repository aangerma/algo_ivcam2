clear;
%
fpNvals=uint32(0:2^20-1);
singleVals=Utils.fp20('to',fpNvals);

zeroZone = singleVals==0;

hObj=plot(fpNvals,singleVals,fpNvals(zeroZone),singleVals(zeroZone),'^g');

getpos = @(e) get(e,'Position');
getelem= @(x,i) x(i);
updtfunc = @(obj,e) {sprintf('%x',getelem(getpos(e),1)),sprintf('%.7f',getelem(getpos(e),2))};

nanValslocs=isnan(singleVals);
 ppp=sort([(hex2dec('01000')+1) (hex2dec('81000')+1) find(singleVals==1) find(singleVals==-1) find(diff(nanValslocs)==1)+1 find(diff(nanValslocs)==-1)-1]);

 yl=get(gca,'ylim');
 for i=1:length(ppp)
     line(double(fpNvals(ppp(i)))*[1 1],get(gca,'ylim'),'color','r','linestyle','--');
     text(double(fpNvals(ppp(i))),yl(1)+diff(yl)/(length(ppp)+1)*i,sprintf('%.5g\n0x%05x(%d)',singleVals(ppp(i)),fpNvals(ppp(i)),fpNvals(ppp(i))));
  end
