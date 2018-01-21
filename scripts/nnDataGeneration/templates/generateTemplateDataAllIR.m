function [] = generateTemplateDataAllIR(rangeFinderDir)
%GENERATETEMPLATEDATAALLIR Summary of this function goes here
% This function receives the path of the head dir. 
% It iterates through the recordings that were made at different distances,
% loads each and seperates them into 64 buckets. Each bucket will receieve
% one template when training in tensorflow. 

    outputDir = 'X:\Data\IvCam2\NN\DCOR\IRFullRange8G';

    % Define the constant sample rate and code length:
    sampleRate = 8;
    
    codeLen = 64;
    prefix = sprintf('%dG_%dCL_',sampleRate,codeLen);
    % Get the transmitted code
    ker=kron(Codes.propCode(codeLen,1),ones(sampleRate,1));

    psnrRegs = getPSNRRegs();
    [amb,regs,luts] = getAmb(psnrRegs);

    % Get the list of the recordings names:
    % rangeFinderDir = 'X:\Data\IvCam2\NN\DCOR\8G_code64_20cm_to_207cm'
    % noiseDir = 
    dir_list = dir(rangeFinderDir);
    dir_list = dir_list(3:end); % Removes the files '.' and '..'
    % Add distance as a field:
    for i = 1:numel(dir_list)
        dir_list(i).z = str2num(dir_list(i).name(4:end-2));
    end
    % Sort by distance:
    [~, ind]=sort([dir_list.z]);
    dir_list=dir_list(ind);

    % Load all data one at a time
    fprintf(' Collecting data from %d files...\n',numel(dir_list))
    errorZ = [];
    ind = 1;
    for i = 1:numel(dir_list)
        tic 
        dir_st = dir_list(i);
        fprintf('Processing dir %s.',dir_st.name)
        try
            ivsArr = io.FG.readFrames(fullfile(rangeFinderDir,dir_st.name,'GplabData\Frames\MIPI_0'));
        catch 
            warning(sprintf('Error reading frames from %s',dir_st.name));
            errorZ = [errorZ;dir_st.z];            
            fclose('all');
            continue
        end
        

        %% Remove non relevant data. Use only whole code chunks.
        begIndx = @(x) find(bitget(x.flags,2),1);
        endInd = @(x)  mod(length(x.fast),length(ker));

        s_=arrayfun(@(x) struct('fast',x.fast((begIndx(x)-1)*64+1:end),'slow',x.slow(begIndx(x):end),'flags',x.flags(begIndx(x):end)),ivsArr);
        s_=arrayfun(@(x) struct('fast',x.fast(1:endInd(x)*64),'slow',x.slow(1:endInd(x)),'flags',x.flags(1:endInd(x))),s_);
        %% Join the splitted data into a continues stream
        ff = [s_.fast];
        slow = [s_.slow];
        slow = slow(slow>0);
        v = buffer_(ff,length(ker));
        v(:,all(v==0))=[];
        vMean = mean(v,2);
        % c = Utils.correlator(v,ker*2-1);
        % imagesc(c)
        corr = Utils.correlator(vMean,ker*2-1);
        ana(ind).psnr = ivs2psnr(amb,strArr2SingleStr(ivsArr),regs,luts);
        ana(ind).z = dir_st.z;
        ana(ind).sampleGT = maxSincInterp(corr)-1;
        ana(ind).irMean = mean(slow);
        ana(ind).numExamples = size(v,2); 
        ana(ind).avgTemplate = getAvgTemplate(v,ana(ind).sampleGT);
        ana(ind).data = v;
        
        example = ana(ind);
        if length(dir_st.name) == 8
            fileName = strcat(prefix,dir_st.name(1:3),'0',dir_st.name(4:end),'.mat');
        else
            fileName = strcat(prefix,dir_st.name,'.mat');
        end
        save(fullfile(outputDir,fileName),'example');
        ind = ind + 1;
        fclose('all');
        fprintf(' Took %2.2f secs.\n',toc)
    end

    figure
    % Plot some interesting graphs
    % Print IR as a function of distance
    subplot(2,2,1);
    plot([ana.z],[ana.irMean],'*')
    xlabel('z(mm)'),ylabel('IR')
    % Print Top sample as a function of distance
    subplot(2,2,2);
    plot([ana.z],[ana.sampleGT],'*')
    xlabel('z(mm)'),ylabel('peak sample index')
    % Print num of examples as a function of distance 
    subplot(2,2,3);
    plot([ana.z],[ana.numExamples],'*')
    xlabel('z(mm)'),ylabel('Num of Examples')
    % Print PSNR as a function of distance 
    subplot(2,2,4);
    plot([ana.z],[ana.psnr],'*')
    xlabel('z(mm)'),ylabel('psnr')
    
    
    splitDataToPsnrBins(outputDir);
%     % The dependency on the IR is limited to 16 bins (as DCOR.irMap is uint4)
%     % I shall split the files to 16 groups according to their IR.
%     irMean = [ana.irMean];
%     [irSorted, ind] = sort(irMean,'descend');
%     if any(irSorted ~= irMean)
%        fprintf('Warning: Mean IR values are not monotonicaly increasing with distance.\n');
%     end
%     irSorted = fliplr(irSorted);
%     numBuckets = 16;
%     irMin = irSorted(1);
%     irMax = irSorted(end);
%     irRange = irMax-irMin;
%     bucketWidth = irRange/numBuckets;
%     buckets = cell(16,1);
%     edge_low = 1;
%     for i = 1:16
%         edge_high = find(irSorted >= irMin+i*bucketWidth,1);
%         buckets{i} = ind(edge_low:edge_high);
%         edge_low = edge_high+1;
%     end
%     binsOcc = cellfun(@(x) numel(x),buckets);
%     bar(binsOcc);
end


function [avgTemp] = getAvgTemplate(v,Igt)
    vMean = mean(v,2);
    avgTemp = circshift(vMean,-round(Igt));
end
function psnr_value = ivs2psnr(amb,ivs,regs,luts)

    ivs.xy = zeros(size(ivs.xy));
    
    [ivs.slow,pipeOut.xyPix, pipeOut.nest, pipeOut.roiFlag]=Pipe.DIGG. DIGG(ivs,regs,luts,Logger,[] );
%     [pipeOut.cma,pipeOut.iImgRAW,pipeOut.aImg,pipeOut.dutyCycle, pipeOut.pipeFlags,pipeOut.pixIndOutOrder, pipeOut.pixRastOutTime ] =...
%         Pipe.RAST.RAST(ivs, pipeOut, regs, luts, Logger,[]);

    iImgRAW = mean(ivs.slow(ivs.slow>1));

    dIR = max(0, int16(iImgRAW)-int16(regs.DCOR.irStartLUT));
    irIndex = map(regs.DCOR.irMap,    min(63, bitshift(dIR, -int8(regs.DCOR.irLUTExp))  )   +1);

    dAmb = max(0, int16(amb)-int16(regs.DCOR.ambStartLUT));
    ambIndex = map(regs.DCOR.ambMap, min(63, bitshift(dAmb, -int8(regs.DCOR.ambLUTExp)))+1);

    psnrIndex = bitor(bitshift(ambIndex, 4), irIndex);
    psnr_value = map(regs.DCOR.psnr, uint16(psnrIndex)+1);
end
function psnrRegs = getPSNRRegs()
    Mcw = 3600;% todo - use the cw recordings. mean(ivs.slow(ivs.slow>0));% Average of the slow channel in the CW recording (Remove zeros)
    [psnrRegs, ~] = Calibration.psnrTableGen(Mcw);
end
function [amb,regs,luts] = getAmb(psnrRegs)
    %% Get the noise estimation:
    noisePath = 'X:\Data\IvCam2\NN\DCOR\8G_noise\Frames\MIPI_0';
    fprintf('Calc noise estimation...\n')
    ivsArr = io.FG.readFrames(noisePath);
    ivs = strArr2SingleStr(ivsArr); % Join the recordings
    % Pass throught the NEST block
    fw = Pipe.loadFirmware('\\Invcam450\d\data\ivcam20\exp\20180101_MA\');
    [regs,luts]=fw.get();

    for fn = fieldnames(psnrRegs.DCOR)'% copy to these regs the psnr configuration
       regs.DCOR.(fn{1}) = psnrRegs.DCOR.(fn{1});
    end
    % Bypas everything that doesn't relate to nest and use the NEST block.
    % Set sample rate and code and code length.
    regs.GNRL.codeLength = 64;
    regs.GNRL.sampleRate = 8;
    regs.GNRL.tmplLength = regs.GNRL.codeLength*regs.GNRL.sampleRate;
    ivs.xy = zeros(size(ivs.xy));
    [ivs.slow,pipeOut.xyPix, pipeOut.nest, pipeOut.roiFlag] = Pipe.DIGG.DIGG(ivs, regs,luts,Logger,[]);
    [pipeOut.cma,pipeOut.iImgRAW,pipeOut.aImg,pipeOut.dutyCycle, pipeOut.pipeFlags,pipeOut.pixIndOutOrder, pipeOut.pixRastOutTime ] =...
        Pipe.RAST.RAST(ivs, pipeOut, regs, luts, Logger,[]);
    amb = pipeOut.aImg(241,321);
    


end
function [sampleNum] = maxSincInterp(corr)
% Interpolates the descrete function using a sinc kernel and returns the
% index of the maximal value.
t = 1:length(corr);
ts = linspace(-5,length(corr)+5,60*length(corr));
[Ts,T] = ndgrid(ts,t);
corr_interp = sinc(Ts - T)*corr;

% plot(t,corr,'o',ts,corr_interp)
% xlabel Sample, ylabel Signal
% legend('Sampled','Interpolated','Location','SouthWest')
% legend boxoff

[~,i] = max(corr_interp);
sampleNum = ts(i);
end