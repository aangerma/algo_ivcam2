fldrs = {'d:\data\ivcam20\exp\20171213\shani\'};
for outDir=fldrs
    outDir=outDir{1};
    
    % outDir =  'd:\data\ivcam20\exp\20171213\plane_2000\';
    basedir = [outDir 'Frames\MIPI_0\'];
    ivs=io.FG.readFrames(basedir,1e3,true,true);
    im=Utils.raw2img(ivs,0,[512 512]);
    imwriteAnimatedGif(im,[outDir '1.gif'])
    io.writeIVS( [outDir 'rec'],ivs);
    Pipe.autopipe(outDir)
    
end