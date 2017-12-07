basedir = 'd:\data\ivcam20\exp\20171204\6\MIPI_0\';
outDir =  'd:\data\ivcam20\exp\20171204\6\';
ivs=io.FG.readFrames(basedir,30,true);
im=Utils.raw2img(ivs,0,[512 512]);
imwriteAnimatedGif(im,[ '1.gif'])
io.writeIVS( [outDir 'rec'],ivs);
