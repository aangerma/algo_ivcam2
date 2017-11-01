function [errF, errSx, errSy] = losTool(ivsInput,verbose)
%mcc -m losTool.m -d \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\POC4RangeFinder\
if(~exist('verbose','var'))
    verbose = false;
end
if(isstruct(ivsInput))
    ivsArr = ivsInput;
else
ivsFilenames = dirRecursive(ivsInput,'*.ivs');
if verbose
    fprintf('losToolSlowAx running on folder:\n\n%s\n\n', ivsInput)
    fprintf('%d ivs files found\n reading ivses...\n',length(ivsFilenames))
end

ivsArr = cellfun(@(ivsFilename) io.readIVS(ivsFilename),ivsFilenames,'UniformOutput',0);
ivsArr = [ivsArr{:}];
end
if length(ivsArr) < 2
    error('losTool need at least 2 ivses to run on');
end
if verbose
fprintf('search for slow channel delay and fast error...');
end
[slowChDelay,~,errF] = Calibration.aux.mSyncerPipe(ivsArr(1),[],verbose);
if verbose
    fprintf('slow channel delay = %d\n', slowChDelay)
    fprintf('generet IR images...')
    figure(11111);imagesc(Utils.raw2slImg(ivsArr(minI),slowChDelay));colormap gray;title('Best Scaneline Image')
end
sz = [1024 1024];
irArr = arrayfun(@(i) Utils.raw2img(ivsArr(i),slowChDelay,sz),1:length(ivsArr),'UniformOutput',0);

indxMat=Utils.indx2col(sz,[5 5]);
for i = 1:length(irArr)
    irArr{i} = reshape(nanmedian(irArr{i}(indxMat)),sz);
  
end
irbox = reshape([irArr{:}],sz(1),sz(2),[]);
irbox(isnan(irbox))=0;
badRows=any(sum(irbox==0,2)>10,3);
badRowsClean = false(size(badRows));
badRowsClean(1:find(~badRows,1))=true;
badRowsClean(find(~badRows,1,'last'):end)=true;
irbox(badRowsClean,:,:)=[];
mm = prctile(irbox(irbox~=0),[5 95]);
irbox=max(0,min(1,(irbox-mm(1))/diff(mm)));
warning('off','vision:calibrate:boardShouldBeAsymmetric');
[imagePoints,bsz] = arrayfun(@(i) detectCheckerboardPoints(irbox(:,:,i)),1:size(irbox,3),'UniformOutput',0);


if isempty(imagePoints{1})
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
if verbose
    fprintf('slow error X:\n%d\n\nslow error Y:\n%d\n\n fast error:\n%d\n', err(1),err(2))
    pointsYoffset = find(~badRowsClean,1);
    for i = 1:length(irArr)
        figure(1000+i);imagesc(irArr{i});colormap gray;title(['IVS: ' ivsFilenames{i}]);
        hold on;plot(ip(i,:)+1j*pointsYoffset,'*');hold off
    end
    figure(1000+i+1);plot(ip,'.');title('Point Groups')
end
end


