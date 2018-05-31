%% LOAD FILES
clear
N_RUNS = 100;
mainDir = 'X:\Data\IvCam2\NN\NNdataset\MPI-Sintel-complete\training\';
%%
albdoFiles =dirRecursive(fullfile(mainDir,'albedo'),'*.png');
depthFiles = strrep(strrep(albdoFiles,fullfile(mainDir,'albedo'),fullfile(mainDir,'depth')),'.png','.dpt');
ok = cellfun(@(x) exist(x,'file')~=0,depthFiles );
albdoFiles=albdoFiles(ok);
depthFiles=depthFiles(ok);
nframes = nnz(ok);
%% REGS SET
regs.GNRL.imgHsize = uint16(640);
regs.GNRL.imgVsize = uint16(480);
regs.FRMW.xfov = single(72);
regs.FRMW.gaurdBandV = single(0);
regs.FRMW.gaurdBandH = single(0);
regs.FRMW.yfov = single(52);
regs.JFIL.dnnBypass = false;
regs.JFIL.innBypass = false;
regs.EPTG.frameRate = single(60);
regs.DIGG.notchBypass = true; % no notch filter
regs.DIGG.gammaBypass = true; % no gamma filter
regs.DEST.baseline=single(30);

rng(12345);
ind = randperm(nframes,N_RUNS);
results=[];
for i=1:N_RUNS
    %%
    zIm = max(0,depth_read(depthFiles{ind(i)})*1000); %mm
    aIm = mean(imread(albdoFiles{ind(i)}),3)/255; %[0 1]
    
    fprintf('%2d/%2d (%04d) generating data...',i,N_RUNS,ind(i));
        [ivsFilename,gt] = Pipe.patternGenerator(regs,'zimg',zIm,'aimg',aIm);
        fprintf('running pipe...');
        pout = Pipe.autopipe(ivsFilename,'verbose',0,'viewResults',0,'saveresults',0);
        pout.gt=gt;
        pout.frameNum = ind(i);
        %%
        outzImg = double(pout.zImg)/double(pout.regs.GNRL.zNorm);
        outzImg(outzImg==0)=nan;
        results=[results pout ];%#ok
        zlim = minmax(outzImg(:));
        ilim = minmax(pout.iImg(:));
        subplot(221)
        imagesc(zIm);title('depth(G)')
        colorbar
        subplot(222)
        imagesc(aIm);title('intensity(G)')
        colorbar
        subplot(223)
        imagescNAN(outzImg);title('depth(R)')
        colorbar
        subplot(224)
        imagesc(pout.iImg);title('intensity(R)')
        colorbar
        fprintf('done\n');
        drawnow;
 

end

% save(fullfile(mainDir,'pipeOut.mat'),'results','-v7.3');    
 




