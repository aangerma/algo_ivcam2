function runPOCanalyzer(inoutFolder,verbose)
if(nargin~=2)
    error('exactly two inputs');
end
params= xml2structWrapper(fullfile(inoutFolder,filesep,'POCconfig.xml'));
if(verbose)
fprintf('starting POC analysis:%s\n\n=====CONFIG BEGIN=====\n%s\n=====CONFIG END=====\n',inoutFolder,struct2str(params,':','\n','  '));
fprintf('reading scope PZR data...');
end
scopeFile = dirRecursive(inoutFolder,'*.h5');
scopeFile = scopeFile{1};
[dt,pzr,indLocs]=aux.readScopeLOS(scopeFile,lower(params.dataMode));
if(verbose),fprintf('done(#frames: %d)\n',length(indLocs));end
%%

if(verbose),fprintf('generating LOS...');end
angxy = aux.extractLOS(pzr,params,dt,verbose);
if(verbose),fprintf('done\n');end
%%
%  indLocs{1}=[194874 3240762];


if(verbose),fprintf('cutting frames/scanlines...');end
xpcDataFull=aux.cutFrames(angxy,dt,indLocs);
if(verbose),fprintf('done\n');end

%
if(verbose),fprintf('reading X0 data...');end
switch(lower(params.dataMode))
    case {'poc4','poc41d','poc4l','poc4l_mc_msync'}
        framesFiles = dirRecursive(inoutFolder,'*.bin');
        isSplitted = cellfun(@(x) ~isempty(strfind(x,'Splitted')),framesFiles);
        framesFiles=framesFiles(isSplitted);
        if(isempty(framesFiles))
            errordlg('No splitted bin files found');
            return
        end
        [ascDataFull] = cellfun(@(i) aux.readRawframe(i),framesFiles,'uni',false);
        
%     case 'poc3'
%         %%
% %         HPF_FREQ=4e6;
%         adcFreq = 125e6;
%         
%         [~,dtrawTIA,rawTIA]=io.POC.readScopeHDF5data(scopeFile,1);%Vsync=Vsync;
%         %%
%         slowOut=rawTIA;
%         
% %         [b,a]=butter(2,HPF_FREQ*dtrawTIA*2,'high');
% %         slowOut = aux.FiltFiltM(b,a,slowOut);
%         %
%         slowOut=abs(slowOut);
%         [b,a]=butter(2,.4*adcFreq*dtrawTIA*2);
%         slowOut = aux.FiltFiltM(b,a,slowOut);
%         
%         
%         
%         tend = length(xpcDataFull{1}.angxQ)*dt;
%         t_ang = xpcDataFull{1}.t0 +(0:length(xpcDataFull{1}.angxQ)-1)*dt;
%         t_tia = (0:length(slowOut)-1)*dtrawTIA;
%         t_out = xpcDataFull{1}.t0 +(0:1/adcFreq:tend);
% 
%         
%         ascDataFull{1}.slow=interp1(t_tia,slowOut,t_out);
%         ascDataFull{1}.slow = uint16(ascDataFull{1}.slow/max(ascDataFull{1}.slow)*(2^12-1));
%         %%
%         ascDataFull{1}.timestamp=xpcDataFull{1}.t0;
%         ascDataFull{1}.vSyncDelay=0;
%         ascDataFull{1}.fast = false(1,length(ascDataFull{1}.slow)*64);
%         ascDataFull{1}.flags = [3 ones(1,length(ascDataFull{1}.slow)-1,'uint8')];
%         xpcDataFull{1}.angxQ=int16(interp1(t_ang,double(xpcDataFull{1}.angxQ),t_out));
%         xpcDataFull{1}.angyQ=int16(interp1(t_ang,double(xpcDataFull{1}.angyQ),t_out));
        
    otherwise
        error('Bad params.dataMode');
end
fprintf('done\n');
%

if(verbose)
fprintf('X0 (%2d):%s\n',length(ascDataFull),mat2str(cellfun(@(x) length(x),ascDataFull)'));
fprintf('XPC(%2d):%s\n',length(xpcDataFull),mat2str(cellfun(@(x) length(x),xpcDataFull)'));
%
fprintf('syncing...\n');
end
%find best value of params.nFrameSkip
%%
ivsArr=cell(5,1);
syncErr=nan(5,1);
for s=1:5
    params.sync.nFrameSkip=s-3;
    if(verbose)
    fprintf('X  %s\n',repmat('-',1,length(xpcDataFull)))
    fprintf(' %s%s\n',repmat(' ',1,max(2,s-1)),repmat('|',1,min(length(xpcDataFull),length(ascDataFull)-s+1)));
    fprintf('A%s%s\n',repmat(' ',1,s-1),repmat('-',1,length(ascDataFull)))
        end
    [ivsArr{s},syncErr(s)]=aux.syncX0XPC(xpcDataFull,ascDataFull,params.sync,verbose);
end
ivsArr=ivsArr{minind(syncErr)};
if(verbose),fprintf('done\n');end

%%
if(isempty(ivsArr))
    error('Could not find sync');
end
%%
for frameNum=1:length(ivsArr)
    if(verbose),   fprintf('writing ivs...');end
    ivsfn = fullfile(inoutFolder,sprintf('record_%02d.ivs',frameNum));
    
    io.writeIVS(ivsfn,ivsArr(frameNum));
    if(verbose),    fprintf('done\n');end
    
%     xy125=ivsArr(frameNum).xyF;
%     xy120=interp1((0:size(xy125,2)-1)/125,xy125',0:1/120:(size(xy125,2)-1)/125)';
%      binfn = fullfile(inoutFolder,sprintf('record_%02d.bin32',frameNum));
%      fid=fopen(binfn,'wb');
%     fwrite(fid,typecast(vec(single(xy120)),'uint32'));
%      fclose(fid);
    
    
end
%%
if(verbose==0)
    return;
end


fprintf('finding sync...');
slowchDelay=Calibration.aux.mSyncerPipe(io.readIVS(ivsfn),[],verbose);
fprintf('Done (%d)\n',slowchDelay);

fprintf('generate image...');
outfn=fullfile(inoutFolder,'ir_raw.gif');
%%
for frameNum=1:length(ivsArr)
    %%
    imgA=aux.ivs2irRaw(ivsArr(frameNum),slowchDelay,[512 512]);
    imgB=aux.ivs2irRaw(ivsArr(frameNum),slowchDelay,[2048 2048],[600 800 512 512]);
    N=11;
    tmp=imgB(Utils.indx2col(size(imgB),[1 N]));
    for i=1:N-1
        bd = tmp(N-i,:)==0;
        tmp(N-i,bd)=tmp(N+1-i,bd);
    end
    imgB=(reshape(tmp(1,:),size(imgB)));
    %     imgB=imdilate(imgB,[1 1 1 1]);
    imgA(imgA==0)=nan;
    imgB(imgB==0)=nan;
    img=[matmap2rgb(imgA,gray(256),[1 99]) matmap2rgb(imgB,gray(256),[1 99])];
    [imind,cm] = rgb2ind(img,256);
    if(frameNum==1)
        imwrite(imind,cm,outfn,'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,outfn,'gif','WriteMode','append');
    end
    if(verbose)
        figure(13);
        clf;
        
        image(img);
        axis image
        drawnow;
    end
end
fprintf('done\n');




fprintf('Finished\n');
end

