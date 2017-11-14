%normalizeByMax
%by Andrey
%
%Linear transforms a positive vector V  to  the range of [0,1] by scaling
%[min,max] -> [0,1]

function res=normByMax(v,p)
if(~exist('p','var') || (exist('p','var') && all(p==[0 100])))
    minmaxv=[min(v(:)) max(v(:))];
else
minmaxv=prctile_(v(:),p);
end
% minv = min(v(:));
% maxv = max(v(:));
minv=minmaxv(1);
maxv=minmaxv(2);
if(minv  == maxv)
    res = v;
else
    res= min(1,max(0,(v-minv)/(maxv-minv)));
end
end
