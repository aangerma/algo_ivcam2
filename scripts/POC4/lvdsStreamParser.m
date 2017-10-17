function [xx,yy]=lvdsStreamParser(vv,dtin,dtout)
mm=minmax(vv);
vv=vv>mean(mm);
rflocs=find(abs(diff(vv))==1);
drflocs=diff(rflocs);
[yy,xx]=hist(drflocs,min(drflocs):max(drflocs));
stepSize=xx(maxind(yy));

samplingPoints = rflocs((drflocs-stepSize)<2 | (drflocs-2*stepSize)<2)+stepSize/2;
samplingPointsIndex = zeros(size(samplingPoints));
for i=2:length(samplingPoints)
    samplingPointsIndex(i)=samplingPointsIndex(i-1)+round(diff(samplingPoints(i-1:i))/stepSize);
end
samplingPointsI=round(interp1(samplingPointsIndex,samplingPoints,0:samplingPointsIndex(end)));
bindata=vv(samplingPointsI);
t=(samplingPointsI-samplingPointsI(1))*dtin;
[x_,y_,t_,u_]=lvdsStreamParser_MEX(bindata,t);
tt = t_(1):dtout:t_(end);


xx = interp1(t_(u_==1),x_(u_==1),tt,'linear','extrap');
yy = interp1(t_(u_==2),y_(u_==2),tt,'linear','extrap');

% figure,plot(xx)
end