function JFILverifier()
 tastStructs = buildTestRegs()
 
 
 
 
doNewIVS = 0;
outDir = 'C:\Users\ychechik\Desktop\JFILverifier';

GTDir =[outDir filesep 'GT'];
workDir = [outDir filesep 'work'];

[baseRegs.FRMW.txCode, baseRegs.GNRL.codeLength] = Codes.bin2uint32(Codes.propCode(32,1));


%% make .ivs
if(doNewIVS)
    eptgRegs = baseRegs;
    eptgRegs.EPTG.seed = single(352);
    %'randomA' image
    eptgRegs.EPTG.zImageType = 2;
    eptgRegs.EPTG.irImageType = 3;
    
    % ground truth
    disp('building GT .ivs');
    mkdirSafe(GTDir);
    eptgRegs.EPTG.frameRate = single(30);
    eptgRegs.EPTG.snr = single(10000); %no snr
    eptgRegs.JFIL.bypass = true; %no JFIL
    Pipe.patternGenerator(eptgRegs,GTDir);
    
    % ivs with 60 FPS
    disp('building work .ivs');
    mkdirSafe(workDir);
    eptgRegs.EPTG.frameRate = single(60);
    eptgRegs.EPTG.snr = single(2);
    Pipe.patternGenerator(eptgRegs,workDir);
end

%% run GT
disp('run: GT')
ivsGT = dirFiles(GTDir,'*.ivs');
ivsGT = ivsGT{1};
outGT = Pipe.autopipe(ivsGT,'viewResults',0,'saveResults',0,'verbose',0);

%% bypass all from work dir & run
disp('run: work')
ivsWork = dirFiles(workDir,'*.ivs');
ivsWork = ivsWork{1};
confingWork = dirFiles(workDir,'config.csv');
confingWork = confingWork{1};

fw = Firmware();
baseRegs = bypassAllJFIL(fw.getRegs(),baseRegs);
fw.setRegs(baseRegs,confingWork);
fw.writeUpdated(confingWork);

[pipeOutData,baseRegs,luts] = Pipe.autopipe(ivsWork,'viewResults',0,'saveResults',0,'verbose',0);

%% test edge filter
tastStructs = buildTestRegs();
outCell = cell(size(tastStructs));

warning('off','FIRMWARE:privUpdate:updateAutogen');
for i = 1:length(tastStructs)
    
    disp('run: doing edge1');
    
    fw.setRegs(baseRegs,confingWork);%reset to original baseRegs
    try
        fw.setRegs(tastStructs{i},confingWork);%only add the configured JFIL testRegs
    catch e
        if (strcmp(e.identifier,'FIRMWARE:privConstraints:ConstraintFailed'))
            out.zRMSE = inf;
            out.iRMSE = inf;
            out.cRMSE = inf;
            outCell{i} = out;
            continue;
        end
    end
    
    %======== run JFIL ========
    [out.zImg,out.iImg, out.cImg ] = Pipe.JFIL.JFIL(pipeOutData,fw.getRegs(),luts,[]);
    figure;imagesc(out.zImg)
    
    
    out.zRMSE = sqrt(mean((out.zImg(:)-outGT.zImg(:)).^2));
    out.iRMSE = sqrt(mean((out.iImg(:)-outGT.iImg(:)).^2));
    out.cRMSE = sqrt(mean((out.cImg(:)-outGT.cImg(:)).^2));
    
    outCell{i} = out;
    
end
warning('on','privUpdate:updateAutogen');

%% compare
[~,zRMSEind] = min(cellfun(@(x) x.zRMSE, outCell(:)));

f = figure;
subplot(3,2,1);imagesc(outCell{zRMSEind}.zImg);title('min RMSE - z image');
subplot(3,2,2);imagesc(outGT.zImg);title('GT z');
subplotCombine(f,[1 2]);
subplot(3,2,3);imagesc(outCell{zRMSEind}.iImg);title('min RMSE - i image');
subplot(3,2,4);imagesc(outGT.iImg);title('GT i');
subplotCombine(f,[3 4]);
subplot(3,2,5);imagesc(outCell{zRMSEind}.cImg);title('min RMSE - c image');
subplot(3,2,6);imagesc(outGT.cImg);title('GT c');
subplotCombine(f,[5 6]);
end






function myRegs=bypassAllJFIL(regs,myRegs)
names = fieldnames(regs.JFIL);
ind = 1:length(names);
ind(cellfun(@(x) isempty(x), regexp(names,'[bB]ypass'))) = [];

for i=1:length(ind)
    if(strfind(names{ind(i)},'bypassMode'))
        myRegs.JFIL.(names{ind(i)}) = uint8(1); %XX1'b is bypass mode in edge & sort
    else
        myRegs.JFIL.(names{ind(i)}) = true;
    end
end
end

function tastStructs = buildTestRegs()
%returns cellArray of regs struct according to wanted configuration
edgeRegs.JFIL.bypass = false;

edgeRegs.JFIL.sort1Edge01 = false; %choose edge filter
edgeRegs.JFIL.edge1bypassMode = uint8(0);



edge1detectTh = 0:100:200;
edge1maxTh = 0:100:200;
for i=1:length(edge1detectTh)
    for j=1:length(edge1maxTh)
        testRegs = edgeRegs;
        testRegs.JFIL.edge1detectTh = uint16(edge1detectTh(i));
        testRegs.JFIL.edge1maxTh = uint16(edge1maxTh(j));
        
        tastStructs{j+(i-1)*length(edge1detectTh)} = testRegs;
    end
end
end
