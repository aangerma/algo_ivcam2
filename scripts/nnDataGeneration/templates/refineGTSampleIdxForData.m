% In this script I shall load all the recorded data. And estimate the delay of
% the device.
% Using the delay of the device, I can estimate the expected index of the
% peak.
% Analize how far are the original estimations from the new ones.

recordingsPath = 'X:\Data\IvCam2\NN\DCOR\IRFullRange8G';

rangeDirs = dir(recordingsPath);
rangeDirs = rangeDirs(3:end);
rangeDirs = rangeDirs([rangeDirs.isdir]);%rangeDirs: Contains a list of the directories - each directory has the recordings for a specific range of psnr/ir

codeLen = 64;
sampleRate = 8;
C = 3*10^8;
binary = kron(Codes.propCode(codeLen,1),ones(sampleRate,1));

n = 1;
for i= 1:numel(rangeDirs)
   records = dir(fullfile(recordingsPath,rangeDirs(i).name) );
   records = records(3:end);
   records = records(~[records.isdir]);
   for j = 1:numel(records)
       
       load(fullfile(recordingsPath,rangeDirs(i).name,records(j).name));
       data(n).v = example.data;
       data(n).z = example.z;
       data(n).sampleGT = example.sampleGT;
       n = n+1;
   end
end


for n = 1:numel(data)
    % 1. Calculate the delay in samples:
    data(n).delay = data(n).z/1000*sampleRate*10^9*2/C - data(n).sampleGT;
    
    % 2. Do the same when not using sinc interpolation. Using the mean of
    % the recordings.
    cb = Utils.correlator(mean(data(n).v,2),binary);
    [~,data(n).peakI] = max(cb);
    data(n).peakI = data(n).peakI - 1;
    data(n).delayFromPeak = data(n).z/1000*sampleRate*10^9*2/C - data(n).peakI;
    % 3. Do the same when when taking the most common peak index. 
    cb = Utils.correlator(data(n).v,binary);
    [~,data(n).commonPeakI] = max(cb,[],1);
    data(n).commonPeakI = mode(data(n).commonPeakI - 1);
    data(n).delayFromCommonPeak = data(n).z/1000*sampleRate*10^9*2/C - data(n).commonPeakI;
     % 3. Do the same when when taking the avg peak index. 
    cb = Utils.correlator(data(n).v,binary);
    [~,data(n).avgPeakI] = max(cb,[],1);
    data(n).avgPeakI = mean(data(n).avgPeakI - 1);
    data(n).delayFromAvgPeak = data(n).z/1000*sampleRate*10^9*2/C - data(n).avgPeakI;
    
end
figure;
ax = [200,2200,-220,-160];
subplot(2,2,1)
plot([data.z],[data.delay],'*')
xlabel('z(mm)'),ylabel('Delay in Samples'), title('Estimated Delay per Recording using sinc interp')
axis(ax)
subplot(2,2,2)
plot([data.z],[data.delayFromPeak],'*')
xlabel('z(mm)'),ylabel('Delay in Samples'), title('Estimated Delay per Recording without interp')
axis(ax)
subplot(2,2,3)
plot([data.z],[data.delayFromCommonPeak],'*')
xlabel('z(mm)'),ylabel('Delay in Samples'), title('Estimated Delay per Recording - using the most common peak')
axis(ax)
subplot(2,2,4)
plot([data.z],[data.delayFromAvgPeak],'*')
xlabel('z(mm)'),ylabel('Delay in Samples'), title('Estimated Delay per Recording - using the avg peak')
axis(ax)

% Now, I shall use the sinc interped data.
% I'll set the delay to be a constant - lets say the average delay of the
% samples below 1000mm (because they are more credible).
dataS = nestedSortStruct(data, 'z');
delay = mean([dataS(1:80).delay]);
delaySTD = std([dataS(80:end).delay]);
refinedZ = 1000*([dataS.sampleGT]+delay)*0.5*C/(sampleRate*10^9);
figure;
subplot(1,2,1)
plot([dataS.z],[[dataS.z];refinedZ])
subplot(1,2,2)
plot([dataS.z],([dataS.z]-refinedZ))



%% Repeat with avg kernel interpolated


for n = 1:numel(dataS)
    sampleGTBin = dataS(n).sampleGT;
    % Get avg kernel
    meanV = mean(dataS(n).v,2);
    avgKer = round(7*(meanV-min(meanV))/(max(meanV)-min(meanV)));
    avgKer = [avgKer;avgKer];
    % Shift the avgKer sampleGT samples backwords...
    newInd = (1:sampleRate*codeLen)+sampleGTBin;
    avgKer = interp1(1:numel(avgKer),avgKer,newInd)';
    corr = Utils.correlator(meanV,avgKer);
    dataS(n).sampleGTAvg = maxSincInterp(corr)-1;
    dataS(n).delayUsingSampleGTAvg = dataS(n).z/1000*sampleRate*10^9*2/C - dataS(n).sampleGTAvg;
   
    
end
figure;
plot([dataS.z],[[dataS(:).sampleGT];[dataS(:).sampleGTAvg]])


%% Show the peak indices distribution across distance with binary template. 
ker = binary;
S = zeros(numel(dataS),numel(binary));
STD = zeros(numel(dataS),1);
commonAndMeanI = zeros(numel(dataS),2);
for n = 1:numel(dataS)
   corr = Utils.correlator(dataS(n).v,binary);
   [~,maxI] = max(corr);
   mostCommonI = mode(maxI);
   [~,meanI] = max(Utils.correlator(mean(dataS(n).v,2),binary));
   commonAndMeanI(n,:) = [meanI,mostCommonI];
   [S(n,:),edges] = histcounts(maxI,0.5:numel(binary)+0.5, 'Normalization', 'probability');
   meanI = mean(maxI);
   diff = abs(maxI - meanI);
   diff(diff>numel(binary)/2) = numel(binary) - diff(diff>numel(binary)/2);
   STD(n) = sqrt(mean(diff.^2));
end
subplot(1,3,1)
imagesc(S(:,200:350)'),xticks(1:5:numel(binary)),yticklabels({}),xticklabels( cellstr(num2str([dataS(1:5:end).z]'))),xtickangle(90),xlabel('z(mm)'),ylabel('Peak Distribution'),title('Peak Distribution Across Z')
subplot(1,3,2)
plot([dataS(:).z],STD,'linewidth',2),axis tight, xlabel('z(mm)'),ylabel('Samples'),title('Peak Indices STD')
subplot(1,3,3)
plot(1:512,S(130,:),'-*'),axis tight, xlabel('Peak Index'),ylabel('Probability'),title('Peak Indices Distribution for 1467mm. STD=81[s] ')

% What is the difference between:
% 1. The gt index from the meanV
% 2. The gt index calculated only fom the mean of v with the most common peak.
ker = binary;
for n = 1:numel(dataS)
   corr = Utils.correlator(dataS(n).v,binary);
   [~,maxI] = max(corr);
   mostCommonI = mode(maxI);
   corr = Utils.correlator(mean(dataS(n).v(:,abs(maxI-mostCommonI)<2),2),binary);
   dataS(n).sampleGTFromCommon = maxSincInterp(corr)-1;
   
end
plot([dataS.z],[[dataS(:).sampleGT];[dataS(:).sampleGTFromCommon]])