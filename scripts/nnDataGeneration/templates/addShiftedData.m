
recordingsPath = 'X:\Data\IvCam2\NN\DCOR\IRFullRange8G';

rangeDirs = dir(recordingsPath);
rangeDirs = rangeDirs(3:end);
rangeDirs = rangeDirs([rangeDirs.isdir]);%rangeDirs: Contains a list of the directories - each directory has the recordings for a specific range of psnr/ir

codeLen = 64;
sampleRate = 8;
C = 3*10^8;
binary = kron(Codes.propCode(codeLen,1),ones(sampleRate,1));
avgFactor = 9;
nAugmentations = 10;
augShift = (0:nAugmentations-1)/nAugmentations;
for i= 1:numel(rangeDirs)
   sprintf('Adding data in dir: %s',rangeDirs(i).name)
   records = dir(fullfile(recordingsPath,rangeDirs(i).name) );
   records = records(3:end);
   records = records(~[records.isdir]);
   for j = 1:numel(records)
       matFilePath = fullfile(recordingsPath,rangeDirs(i).name,records(j).name);
       load(matFilePath);
       
       mV = mean(example.data,2);
       corr = Utils.correlator(mV,binary);
       example.sampleGTParabFit = parabFit(corr)-1;
       
       example.dataShifted = shiftColumnsByNum(example.data,example.sampleGTParabFit-16);
       nSamples = size(example.dataShifted,2);
       newNSamples = floor(nSamples/9)*9;
       example.dataShifted = example.dataShifted(:,1:newNSamples);
       example.avgTmpl = shiftColumnsByNum(mean(example.data,2),example.sampleGTParabFit);
       example.dataShiftedAug = zeros(codeLen*sampleRate,nAugmentations*newNSamples);
       example.dataShiftedAugIgt = zeros(1,nAugmentations*newNSamples);
       for augI = 1:length(augShift)
            
            augData = shiftColumnsByNum(example.data(:,1:newNSamples),example.sampleGTParabFit-16-augShift(augI));
            augData = augData(:,randperm(newNSamples));
            example.dataShiftedAug(:,1+(augI-1)*newNSamples:augI*newNSamples) = augData;
            
            mV = mean(augData,2);
            corr = Utils.correlator(mV,binary);
%             x1(augI) = maxSincInterp(corr)-1;
%             y1(augI) = parabFit(corr)-1;
            example.dataShiftedAugIgt(1+(augI-1)*newNSamples:augI*newNSamples) =  parabFit(corr)-1;
       end
%        for augI = 1:length(augShift)
%             
%             augData = shiftColumnsByNum(example.data(:,1:newNSamples),example.sampleGT-16-augShift(augI));
%             augData = augData(:,randperm(newNSamples));
%             example.dataShiftedAug(:,1+(augI-1)*newNSamples:augI*newNSamples) = augData;
%             
%             mV = mean(augData,2);
%             corr = Utils.correlator(mV,binary);
%             x2(augI) = maxSincInterp(corr)-1;
%             y2(augI) = parabFit(corr)-1;
%             example.dataShiftedAugIgt(1+(augI-1)*newNSamples:augI*newNSamples) =  y2(augI);
%        end
%        diffParab(i,j) = mean(abs(16+augShift-y1));
%        diffSinc(i,j) = mean(abs(16+augShift-x2));
%        plot(augShift,[16+augShift;y1;x2]);
       
       save(matFilePath,'example');
       
   end
   
end
% stem([diffParab(diffParab>0),diffSinc(diffSinc>0)],'filled','LineStyle','none')
% grid on
% title('Index Errors After Shifting')
% legend({'parab err' 'sinc err'})
% xlabel('Recording #')
% ylabel('Sample Error')
