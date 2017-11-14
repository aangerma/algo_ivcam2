function m = buffer_(v,r,colCross)
%uusage: m = buffer(v,r,c)
% v - input signal
% r - number of output rows
% colCross -index jump between rows
if(~exist('colCross','var'))
    colCross = r;
end
if(numel(v)<=r)
    m = [v(:);zeros(r-length(v),1)];
    return;
end
r = round(r);
colCross = round(colCross);

colCross =0:colCross:length(v)-1;
n=bsxfun(@plus,(1:r)',colCross);
vv = [v(:);zeros(n(end,end)-length(v),1)]';

m = vv(n);

end