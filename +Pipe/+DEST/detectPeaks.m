function [peaks,mxMainLobe] = detectPeaks(corrFineSmooth,corrOffset,fastApprox)

[s,h,w]=size(corrFineSmooth);
[mxMainLobe,mx] = max(corrFineSmooth);
if(0)
    mx = min(max(mx,2),s-1);%#ok
    d1 = bsxfun(@plus,mx,(-1:1)');
    offsetTotal = permute(single(mx),[2 3 1])+corrOffset;
    [~,d2,d3]=ndgrid(-1:1,1:h,1:w);
    ind=sub2ind([s,h,w],d1,d2,d3);
    corrw = int32(corrFineSmooth(ind));
else
    d1 = bsxfun(@plus,mx,(-1:1)');
    offsetTotal = permute(single(mx),[2 3 1])+corrOffset;
    [~,d2,d3]=ndgrid(-1:1,1:h,1:w);
    corrFineSmoothZP = cat(1,zeros(1,h,w),corrFineSmooth,zeros(1,h,w));
    ind=sub2ind([s+2,h,w],d1+1,d2,d3);
    corrw = int32(corrFineSmoothZP(ind));
end




corrw=permute(corrw,[2 3 1]);
%%
dnm = single(corrw(:,:,1)+corrw(:,:,3)-2*corrw(:,:,2));
if(fastApprox)
    dnmInv = 1./single(dnm);
else
    dnmInv = Utils.fp32('inv',dnm);
end
num = corrw(:,:,1)-corrw(:,:,3);
peaks = single(num).*dnmInv*single(0.5);%leave div/0 as NaN
peaks = peaks +offsetTotal;


mxMainLobe = permute(mxMainLobe,[2 3 1]);



end


