function regsOut = trigoCalcs(regs)
xfovPix = regs.FRMW.xfov * (1-regs.FRMW.gaurdBandH*2);
yfovPix = regs.FRMW.yfov * (1-regs.FRMW.gaurdBandV*2);
if(regs.DIGG.undistBypass==0)
    xfovPix = xfovPix*regs.FRMW.undistXfovFactor;
    yfovPix = yfovPix*regs.FRMW.undistYfovFactor;
end
regsOut.DEST.p2axa = ( tand(xfovPix/2)* 2    / single(regs.FRMW.xres-1));
regsOut.DEST.p2axb = (-tand(xfovPix/2)*(1-2 *single(regs.FRMW.marginL) / single(regs.FRMW.xres) + single(regs.FRMW.xoffset) ));




if(regs.GNRL.rangeFinder)
    regsOut.DEST.p2aya = single(0);
    regsOut.DEST.p2ayb  = single(0);
else
regsOut.DEST.p2aya = ( tand(yfovPix/2)* 2    / single(regs.FRMW.yres-1));
regsOut.DEST.p2ayb = (-tand(yfovPix/2)*(1-2 *single(regs.FRMW.marginT) / single(regs.FRMW.yres) + single(regs.FRMW.yoffset) ));
end

Kinv=[regsOut.DEST.p2axa 0                   regsOut.DEST.p2axb;
   0                  regsOut.DEST.p2aya  regsOut.DEST.p2ayb;
   0                  0                   1];

K=pinv(Kinv);
regsOut.CBUF.spare=typecast(K([1 4 7 2 5 8 3 6]),'uint32');
end