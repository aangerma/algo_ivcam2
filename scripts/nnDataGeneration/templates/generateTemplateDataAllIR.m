function [] = generateTemplateDataAllIR(rangeFinderDir)
%GENERATETEMPLATEDATAALLIR Summary of this function goes here
% This function receives the path of the head dir. 
% It iterates through the recordings that were made at different distances,
% loads each and seperates them into 64 buckets. Each bucket will receieve
% one template when training in tensorflow. 

    % Define the constant sample rate and code length:
    sampleRate = 16;
    codeLen = 64;
    prefix = sprintf('%dG_%dCL_',sampleRate,codeLen);
    % Get the transmitted code
    ker=kron(Codes.propCode(codeLen,1),ones(sampleRate,1));


    % Get the list of the recordings names:
    % rangeFinderDir = 'X:\Data\IvCam2\NN\DCOR\8G_code64_20cm_to_207cm'
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
    dir_list = dir_list(1:16);
    for i = 1:numel(dir_list)
        if i>16
            break;
        end
        dir_st = dir_list(i);
        fprintf('Processing dir %s.\n',dir_st.name)
        f = dirFiles(fullfile(rangeFinderDir,dir_st.name,'GplabData\Splitted\MIPI_0'),'Splitted*.bin');
        s = cellfun(@(x) aux.readRawframe(x),f,'uni',0);
        s = [s{:}];

        %% Remove non relevant data. Use only whole code chunks.
        begIndx = @(x) find(bitget(x.flags,2),1);
        endInd = @(x)  mod(length(x.fast),length(ker));

        s_=arrayfun(@(x) struct('fast',x.fast((begIndx(x)-1)*64+1:end),'slow',x.slow(begIndx(x):end),'flags',x.flags(begIndx(x):end)),s);
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
        ana(i).z = dir_st.z;
        ana(i).sampleGT = maxSincInterp(corr)-1;
        ana(i).irMean = mean(slow);
        ana(i).numExamples = size(v,2); 
        ana(i).avgTemplate = getAvgTemplate(v,ana(i).sampleGT);
        ana(i).data = v;
        
        example = ana(i);
        if length(dir_st.name) == 8
            fileName = strcat(prefix,dir_st.name(1:3),'0',dir_st.name(4:end),'.mat');
        else
            fileName = strcat(prefix,dir_st.name,'.mat');
        end
         save(fullfile('X:\Data\IvCam2\NN\DCOR\IRFullRange',fileName),'example');
    end

    figure
    % Plot some interesting graphs
    % Print IR as a function of distance
    subplot(1,3,1);
    plot([ana.z],[ana.irMean],'*')
    xlabel('z(mm)'),ylabel('IR')
    % Print Top sample as a function of distance
    subplot(1,3,2);
    plot([ana.z],[ana.sampleGT],'*')
    xlabel('z(mm)'),ylabel('peak sample index')
    % Print num of examples as a function of distance 
    subplot(1,3,3);
    plot([ana.z],[ana.numExamples],'*')
    xlabel('z(mm)'),ylabel('Num of Examples')
    
    % The dependency on the IR is limited to 16 bins (as DCOR.irMap is uint4)
    % I shall split the files to 16 groups according to their IR.
    irMean = [ana.irMean];
    [irSorted, ind] = sort(irMean,'descend');
    if any(irSorted ~= irMean)
       fprintf('Warning: Mean IR values are not monotonicaly increasing with distance.\n');
    end
    irSorted = fliplr(irSorted);
    numBuckets = 16;
    irMin = irSorted(1);
    irMax = irSorted(end);
    irRange = irMax-irMin;
    bucketWidth = irRange/numBuckets;
    buckets = cell(16,1);
    edge_low = 1;
    for i = 1:16
        edge_high = find(irSorted >= irMin+i*bucketWidth,1);
        buckets{i} = ind(edge_low:edge_high);
        edge_low = edge_high+1;
    end
    binsOcc = cellfun(@(x) numel(x),buckets);
    bar(binsOcc);
end


function [avgTemp] = getAvgTemplate(v,Igt)
    vMean = mean(v,2);
    avgTemp = circshift(vMean,-round(Igt));
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