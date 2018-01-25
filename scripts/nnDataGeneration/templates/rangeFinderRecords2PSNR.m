%% Use the recorded cw and noise test to get the noise estimation and the Mcw needed to determine PSNR.

%% Get the psnr regs using the Mcw 
McwPath = 'X:\Data\IvCam2\NN\DCOR\02012018\8G_64b_0xffffff(cw)\Frames\MIPI_0';
fprintf('Calc Mcw estimation...\n')
ivsArr = io.FG.readFrames(McwPath);
ivs = strArr2SingleStr(ivsArr);
Mcw = 3600;% todo - use the cw recordings. mean(ivs.slow(ivs.slow>0));% Average of the slow channel in the CW recording (Remove zeros)

[psnr_regs, ~] = Calibration.psnrTableGen(Mcw);

%% Get the noise estimation:
noisePath = 'X:\Data\IvCam2\NN\DCOR\8G_noise\Frames\MIPI_0';
fprintf('Calc noise estimation...\n')
ivsArr = io.FG.readFrames(noisePath);
ivs = strArr2SingleStr(ivsArr); % Join the recordings
% Pass throught the NEST block
[fw,p] = Pipe.loadFirmware();
[regs,luts] = fw.get();% Get default regs
for fn = fieldnames(psnr_regs.DCOR)'% copy to these regs the psnr configuration
   regs.DCOR.(fn{1}) = psnr_regs.DCOR.(fn{1});
end
% Bypas everything that doesn't relate to nest and use the NEST block.
% Set sample rate and code and code length.
regs.GNRL.codeLength = 64;
regs.GNRL.sampleRate = 8;
regs.GNRL.tmplLength = regs.GNRL.codeLength*regs.GNRL.sampleRate;
lgr = Logger(p.verbose,false,fullfile(p.outputDir,'log.log'));
ivs.xy = zeros(size(ivs.xy));
[ivs.slow,pipeOut.xyPix, pipeOut.nest, pipeOut.roiFlag] = Pipe.DIGG.DIGG(ivs, regs,luts,lgr,p.traceOutDir);
[pipeOut.cma,pipeOut.iImgRAW,pipeOut.aImg,pipeOut.dutyCycle, pipeOut.pipeFlags,pipeOut.pixIndOutOrder, pipeOut.pixRastOutTime ] =...
    Pipe.RAST.RAST(ivs, pipeOut, regs, luts, lgr,p.traceOutDir);

amb = pipeOut.aImg(241,321);

%% For each distance recording, calculate the psnr index:
rangeFinderMatDir = 'X:\Data\IvCam2\NN\DCOR\IRFullRange8G';
dir_list = dir(rangeFinderMatDir);
dir_list = dir_list(3:end); % Removes the files '.' and '..'
for i = 1%1:numel(dir_list)
    dir_st = dir_list(i);
    fprintf('Processing file %s.\n',dir_st.name)
    load(fullfile(rangeFinderMatDir,dir_st.name));
    ana
end
    % Run the psnr index calculation (copied from the DCOR):
    % PSNR
    



