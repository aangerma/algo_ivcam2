basedir = 'd:\data\ivcam20\exp\20171211\Frames\MIPI_0\';
outDir =  'd:\data\ivcam20\exp\20171211\';
ivs=io.FG.readFrames(basedir,30,true,true);
im=Utils.raw2img(ivs,0,[512 512]);
imwriteAnimatedGif(im,[outDir '1.gif'])
io.writeIVS( [outDir 'rec'],ivs);
