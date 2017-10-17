clear;
%%%PLOT SPECTRUM
% vfn = '\\invcam322\ohad\SOURCE\IVCAM\Algo\Applications\CodeFinder\x64\Release\output_66.txt';
 vfn = 'D:\ohad\SOURCE\IVCAM\Algo\Applications\CodeFinder\x64\Release\output_32MC_SL2.txt';
vBuff = fileReadNumeric(vfn)';

fprintf('Code length: %d, N codes: %d\n',size(vBuff,1),size(vBuff,2));

%cBuff = Utils.correlator(vBuff,vBuff*2-1);

%% cross corr
score = @(x) max(x)-max(x([1:maxind(x)-1 maxind(x)+1:end]));
ccor = int32(nan(size(vBuff,2),size(vBuff,2),size(vBuff,1)));
for y=1:size(vBuff,2)
    ccor(y,:,:)=Utils.correlator(vBuff*2-1,vBuff(:,y))';
end
%%
clf
cscore = nan(size(vBuff,2));
parfor i=1:(size(vBuff,2)*size(vBuff,2))
    [y,x]=ind2sub(    [size(vBuff,2),size(vBuff,2)],i);
    cscore(i)=score(ccor(y,x,:));
end
imagesc(cscore)
%%
xcClean=cscore;
xcClean = xcClean-diag(diag(xcClean));
ind=1:size(vBuff,2);

while(true)
    sCrr = sum(xcClean);
    [mxval,mxind] = max(sCrr);
    if(max(xcClean)<=1)
        break;
    end
    ind(mxind)=[];
    xcClean(mxind,:)=[];
    xcClean(:,mxind)=[];
    [size(xcClean,1) mxval]
     imagesc(xcClean);
    drawnow;
    
end
%%
N = length(ind);
for i=1:(N*N)
    [y,x]=ind2sub(    [N,N],i);
     subaxis(N,N,i,'margin',0,'padding',0,'Spacing',0);
    plot(circshift(squeeze(ccor(ind(y),ind(x),:)),size(ccor,3)/2));set(gca,'ylim',[min(ccor(:))-1 max(ccor(:))+1],'xlim',[1 size(ccor,3)],'XTickLabel',[],'YTickLabel',[]);
end
%%
arrayfun(@(i) fprintf('DATA{%d}{end+1}=%s;\n',size(vBuff,1),mat2str(vBuff(:,i)')),ind)