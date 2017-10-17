
load(fullfile(mainDir,'pipeOut.mat'));    
 
%% typeA netowrk depth data generation
tAdata_Z=[];
tAdata_I=[];
for i=1:length(results)
    %%
    refImgZ = single(results(i).gt.zImg);
    refImgI = single(results(i).gt.aImg);
    fvecZ = Utils.fp20('to',reshape(results(i).nnfeatures.d,numel(refImgZ),[])');
    fvecI = Utils.fp20('to',reshape(results(i).nnfeatures.i,numel(refImgZ),[])');
    rpatch=refImgZ(Utils.indx2col(size(refImgZ),[3 3]));
    mask = single(any(rpatch<3500));
    refImgZ=min(1,refImgZ/single(results(i).regs.FRMW.nnMaxRange));
    tAdata_Z = [tAdata_Z [fvecZ;refImgZ(:)';mask(:)']];%#ok
    tAdata_I = [tAdata_I [fvecI;refImgI(:)';mask(:)']];%#ok

    disp(i)
    
    
    
end
nnTypeA_Zfn = fullfile(mainDir,'nnTypeA_Z.bin');
fid = fopen(nnTypeA_Zfn,'wb');
fwrite(fid,typecast(vec(single(tAdata_Z)),'uint32'),'uint32');
fclose(fid);
nnTypeA_Ifn = fullfile(mainDir,'nnTypeA_I.bin');
fid = fopen(nnTypeA_Ifn,'wb');
fwrite(fid,vec(single(tAdata_I)),'single');
fclose(fid);

copyfile(nnTypeA_Zfn,'\\perclnx53\ohaData\input\');
copyfile(nnTypeA_Ifn,'\\perclnx53\ohaData\input\');
fprintf('Done\n');
