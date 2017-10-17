function [xyColsAll,xfov,yfov]=readLocation(fn,flavorType)
xyCut=Extract_LOS(fn,1,flavorType);
n = cellfun(@(x) length(x),xyCut.Time)~=0;
xyColsAll=cell(length(xyCut),1);
maxCell = @(a) max(cellfun(@(x) max(x),a));
minCell = @(a) max(cellfun(@(x) min(x),a));
xfov=maxCell(xyCut.SA_LOS_Filt(n))-minCell(xyCut.SA_LOS_Filt(n));
yfov=maxCell(xyCut.FA_LOS_Filt(n))-minCell(xyCut.FA_LOS_Filt(n));
nFrames = length(xyCut.FA_LOS_Filt);
for frameNumber=1:nFrames
    %%
    angx = xyCut.SA_LOS_Filt{frameNumber};
    angy = xyCut.FA_LOS_Filt{frameNumber};
    vsync = xyCut.Vsync{frameNumber};
    % hsync = xyCut.Hsync{frameNumber};
    t = xyCut.Time{frameNumber};
    %%
    
    c = find(abs(diff(vsync>.5))==1);
    %%
    
    angxQ = angx/xfov;
    angyQ = angy/yfov;
    %%
    xyCols=struct([]);
    for i=1:length(c)-1
        xyCols(i).angxQ = vec(min(1,max(-1,angxQ(c(i):c(i+1))))*2*(2^11-1))';
        xyCols(i).angyQ = vec(min(1,max(-1,angyQ(c(i):c(i+1))))*2*(2^11-1))';
        
        xyCols(i).t0 = t(c(i));
    end
    xyColsAll{frameNumber}=xyCols;
end
xyColsAll=xyColsAll(cellfun(@(x) ~isempty(x),xyColsAll));
end