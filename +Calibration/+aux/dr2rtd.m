function rtd = dr2rtd(z, regs)

if ~regs.DEST.depthAsRange
    [~,r] = Pipe.z16toVerts(z,regs);
else
    r = double(z)/bitshift(1,regs.GNRL.zMaxSubMMExp);
end
% get rtd from r
[~,~,~,~,~,~,sing] = Pipe.DEST.getTrigo(size(r),regs);

C = 2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd = r+sqrt(r.^2-C);
rtd = rtd+regs.DEST.txFRQpd(1);