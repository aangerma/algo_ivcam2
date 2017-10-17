

function c = getPulseTimes(dt,v,thr)
    if(~exist('thr','var'))
        thr = mean(v(~isnan(v(:))));
    end
    v=v(:)-thr;

ind = (diff(v(:)<0)==-1) | (diff(v(:)>0)==-1);
ind(end)=false;
ind =find(ind);
%remove first "high"
if(v(ind(1))>0)
    ind(1)=[];
end
y0 = v(ind);
y1 = v(ind+1);
x0 =(ind-1)*dt;

x=-y0*dt./(y1-y0)+x0;
n = length(x);
x = x(1:n-mod(n,2));
x = reshape(x,2,[]);
d=median(diff(x));
c = mean(x)-d/2;
c=c(:);
end
