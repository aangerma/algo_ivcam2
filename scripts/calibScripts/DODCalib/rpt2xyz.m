function [xyz] = rpt2xyz(rpt,regs)

r = rpt(:,1)/2;
angx = rpt(:,2);
angy = rpt(:,3);

[~,~,oXYZ] = myang2xy(angx,angy,regs,1);
xyz = bsxfun(@times,oXYZ',r);
end

