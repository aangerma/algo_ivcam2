ivs=io.FG.readFrames('\\ger\ec\proj\ha\perc\SA_3DCam\shani.k\Frames_rec_minus592ns_fix_900vscans_depth61cm\Frames\MIPI_0\','numFrames',1);
%%
outfn=fullfile('ir_raw.gif');
for i=1:length(ivs)
    irraw = Utils.raw2img(ivs{i},74,[512 512]);
    img=matmap2rgb(irraw,gray(256),[1 99]);
    [imind,cm] = rgb2ind(img,256);
    if(i==1)
        imwrite(imind,cm,outfn,'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,outfn,'gif','WriteMode','append');
    end
end