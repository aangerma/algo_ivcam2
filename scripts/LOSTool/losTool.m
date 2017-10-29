function [errF, errSx, errSy] = losTool(baseDir)
%mcc -m losTool.m -d \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\POC4RangeFinder\ 
verbose=true;
ivsFilenames = dirRecursive(baseDir,'*.ivs');


fprintf('losToolSlowAx running on folder:\n\n%s\n\n', baseDir)
fprintf('%d ivs files found\n reading ivses...\n',length(ivsFilenames))
if length(ivsFilenames) < 2
    error('losTool need at least 2 ivses to run on');
end
ivsArr = cellfun(@(ivsFilename) io.readIVS(ivsFilename),ivsFilenames,'UniformOutput',0);

fprintf('search for slow channel delay and fast error...');
[slowChDelay,errF] = Calibration.aux.mSyncerPipe(ivsArr{1},[],verbose);
% warning off;
% [~,slowChDelay,errFArr] = cellfun(@(ivs)Calibration.aux.mSyncerPipe(ivs,[],verbose),ivsArr);
% warning on;
% if any(slowChDelay(1:end-1) ~= slowChDelay(end))
%     warning('not all ivses have equal slowchannelDelay!!!');
% end
% [errF, minI] = nanmin(errFArr);
% slowChDelay = slowChDelay(minI);
fprintf('slow channel delay = %d\n', slowChDelay)
fprintf('generet IR images...')
sz = [1024 1024];
irArr = cellfun(@(ivs) Utils.raw2img(ivs,slowChDelay,sz),ivsArr,'UniformOutput',0);

indxMat=Utils.indx2col(sz,[3 3]);
for i = 1:length(irArr)
    irArr{i} = reshape(nanmedian(irArr{i}(indxMat)),sz);
end
irbox = reshape([irArr{:}],sz(1),sz(2),[]);
irbox(isnan(irbox))=0;
badRows=any(any(irbox==0,2),3);
badRowsClean = false(size(badRows));
badRowsClean(1:find(~badRows,1))=true;
badRowsClean(find(~badRows,1,'last'):end)=true;
irbox(badRowsClean,:,:)=[];
mm = prctile(irbox(:),[10 90]);
irbox=(irbox-mm(1))/diff(mm);
warning off;
[imagePoints,bsz] = arrayfun(@(i) detectCheckerboardPoints(irbox(:,:,i)),1:size(irbox,3),'UniformOutput',0);
warning on;

if isempty(bsz{1})
    error('cant find checker board point!!!')
end
if(size(unique(reshape(cell2mat(bsz),2,[])','rows'),1)~=1)
    error('checker board point numbers not equal in all images!!!')
end
distfunc = @(v) max(abs([vec(real(v(:)-v(:).')), vec(imag(v(:)-v(:).'))]));

ip=cell2mat(cellfun(@(x) (x(:,1)+1j*x(:,2)),imagePoints,'uni',0)).';
err = max(reshape(cell2mat(arrayfun(@(i) distfunc(ip(:,i)),1:size(ip,2),'UniformOutput',0)),2,size(ip,2)),[],2);
errSx = err(1);
errSy = err(2);
fprintf('slow error X:\n%d\n\nslow error Y:\n%d\n\n fast error:\n%d\n', err(1),err(2))
end


