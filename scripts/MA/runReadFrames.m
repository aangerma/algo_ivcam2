basedir = 'D:\data\ivcam20\exp\20171211\Frames\MIPI_0';
outDir =  'D:\data\ivcam20\exp\20171211\';
ivs=io.FG.readFrames(basedir,30,true);
im=Utils.raw2img(ivs,0,[512 512]);
imwriteAnimatedGif(im,[ '1.gif'])
io.writeIVS( [outDir 'rec'],ivs);
