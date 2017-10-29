function [ivsArr,syncErr]=syncX0XPC(xpcDataFull,ascDataFull,params,verbose)
ivsArr=[];
nFrameSkip=params.nFrameSkip;
precut=params.precut;

if(nFrameSkip>0)
    xpcDataFull=xpcDataFull(nFrameSkip+1:end);%asic 1st frame drop
elseif(nFrameSkip<0)
    ascDataFull = ascDataFull(-nFrameSkip+1:end);
end
SCAN_DIR_BIT = 3;

nframes = min(length(xpcDataFull),length(ascDataFull));

lfit = @(x) [(1:length(x))' x(:)*0+1]\(x(:)-x(1));
if(verbose),fprintf('\n');end
syncErr=inf;
for frameNum=1:nframes
    %%
    
    %eval scale
    xpcSyncLocs = ([xpcDataFull{frameNum}.t0]-xpcDataFull{frameNum}(1).t0)*1e9;
    asicSyncLocs=double(([ascDataFull{frameNum}.timestamp]-uint64([ascDataFull{frameNum}.vSyncDelay])))/64*8;
    
    xpc_m = lfit(xpcSyncLocs);
    asc_m = lfit(asicSyncLocs);
    scaleFactor=iff(asc_m(1)==xpc_m(1),1,xpc_m(1)/asc_m(1));
    
    asicSyncLocs = asicSyncLocs*scaleFactor;
    
    
    
    %
    %correlate XPC and ASIC vsyncs
    
    indMap = bsxfun(@plus,(1:length(asicSyncLocs)-precut*2)',0:length(xpcSyncLocs)-length(asicSyncLocs)+precut*2);
    c = (sum(abs(bsxfun(@minus,diff(xpcSyncLocs(indMap)),diff(asicSyncLocs(precut+1:end-precut)')))));
    cm = iff(sum(c)==0,0,minind(c)-precut-1);
    if(cm>0)
        xpcLocs=xpcDataFull{frameNum}(cm+1:end);
        x0Data = ascDataFull{frameNum};
    else
        xpcLocs=xpcDataFull{frameNum};
        x0Data = ascDataFull{frameNum}(-cm+1:end);
    end
    
    nVscans = min(length(xpcLocs),length(x0Data));
    
    x0Data = x0Data(1:nVscans);
    xpcLocs = xpcLocs(1:nVscans);
    
    %
    asicSyncLocs2=double(([x0Data.timestamp]-uint64([x0Data.vSyncDelay])))/64*8*scaleFactor;
    xpcSyncLocs2 = ([xpcLocs.t0]-xpcLocs(1).t0)*1e9;
    e = sqrt(mean((diff(asicSyncLocs2-xpcSyncLocs2).^2)));
    syncErr = min(syncErr,e);
    
    if(verbose)
        %%
        fprintf('%d/%d\t',frameNum,nframes);
        fprintf('scaleFactor=%f\t',scaleFactor);
        fprintf('#XPC=%d\t',length(xpcLocs));
        fprintf('#X0=%d\t',length(x0Data));
        fprintf('rms=%f\t',e);
        
        figure(3431);
        subplot(211)
        plot(diff(xpcSyncLocs));
        hold on
        plot(diff(asicSyncLocs));
        hold off
        title('before');
        subplot(212);
        
        
        zzz=xpcSyncLocs2(1:nVscans)-(asicSyncLocs2(1:nVscans))*scaleFactor;
        plot(zzz(2:end)-mean(zzz));
        plot(diff(xpcSyncLocs2));
        hold on
        plot(diff(asicSyncLocs2));
        hold off
        
        drawnow;
        title('after');
        legend('XPC','ASIC')
    end
    if(e>10)
        if(verbose),fprintf('SKIPPED\n');end
        continue;
    end
    %% sync from v-syncs
    frst_scan_dir = mean(diff(xpcLocs(1).angy))>0;
    for i=1:nVscans
        
        xyI = [xpcLocs(i).angx;xpcLocs(i).angy];
        nout = length(x0Data(i).slow);
        nin  = size(xyI,2);
        x0Data(i).xy =       interp1(linspace(0,1,nin), double(xyI'),linspace(0,1,nout))';
        x0Data(i).xy = max(-2^11+1,min(2^11-1,x0Data(i).xy));
        x0Data(i).flags=bitset(x0Data(i).flags,SCAN_DIR_BIT,uint8(mod(i-1+frst_scan_dir,2)));
        
    end
    %create IVS
    ivs.fast = [x0Data.fast];
    ivs.slow = [x0Data.slow];
    ivs.flags= [x0Data.flags];
    
    ivs.xy = int16(round([x0Data.xy ]));
    ivs.xyF = [x0Data.xy ];
    ivs.flags(1) = bitor(ivs.flags(1),2); %set tx_code_start to 1 on first chunk
    
    
    
    %     %% fix scan dir flag
    %     scanDirBitNum = 3;
    %     scanDir = bitget(ivs.flags, scanDirBitNum, 'uint8');
    %
    %     scanDirChange = zeros(size(scanDir),'logical');
    %     scanDirChange(1:end-1) = int8(scanDir(1:end-1))-int8(scanDir(2:end)) ~= 0;
    %     scanDirChange(end) = 0;
    %
    %     PHASE =  1535;%1480; %FIXED
    %     scanDirChange = [scanDirChange(PHASE:end) zeros(1,PHASE-1)];
    %
    %     scanDirChangeInd = find(scanDirChange==1);
    %    isDown = (double(ivs.xy(2, scanDirChangeInd(1))) - double(ivs.xy(2, scanDirChangeInd(2)))) >0;%to find the right direction...
    %
    %     scanDirBit = mod(cumsum(scanDirChange)+isDown,2);
    %
    %     ivs.flags= bitor(bitand(ivs.flags,uint8(2^8-1-2^(scanDirBitNum-1)),'uint8'),uint8(scanDirBit)*uint8(2^(scanDirBitNum-1)), 'uint8');
    %
    % if(0)
    %     %%
    %     scanDirBitNum = 3;
    %     scanDir = bitget(ivs.flags, scanDirBitNum, 'uint8');
    %
    %     figure(11012);clf
    %     n = 1:100000;
    %     y = double(ivs.xy(2,:));
    %     plot(y(n),'-*');
    %     hold on;plot(max(y)*(double(scanDir(n))-0.5)*2,'*r')
    %     title('y and scan dir')
    %
    %     xNew = cumsum(scanDirChange);
    %     figure(3243);clf;plot(xNew(1,1:100000),ivs.xy(2,1:100000),'-*');title('xy map')
    %
    % end
    %%
    
    ivsArr=[ivsArr ivs];%#ok
    
    if(verbose),fprintf('done\n');end
    
end


end