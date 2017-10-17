function [z,r,x,y]=rtd2depth(rtd,regs)

[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(size(rtd),regs);



dnm = (rtd - regs.DEST.baseline.*sing);
%     dnm = (rtd - regs.DEST.baseline.*sinx); %BUG
if(regs.MTLB.fastApprox(2))
    calcDenum = 1./ dnm;
else
    calcDenum = Utils.fp32('inv',dnm);
end

r= (0.5*(rtd.^2 - regs.DEST.baseline2)).*calcDenum;

% lgr.print2file(sprintf('\trange = %X\n',typecast(r(lgrOutPixIndx),'uint32')));

%% calc depth
z = r;
if (~regs.DEST.depthAsRange)
    coswx=cosw.*cosx;
    z = z.*coswx;
    %         z = z.*cosy.*cosx; %BUG
end
%%
%FOR INTERNAL USE (NON ASIC)
x = r.*cosy.*sinx;
y = r.*sinw;
end