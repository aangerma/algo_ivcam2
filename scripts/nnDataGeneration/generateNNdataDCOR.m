%% LOAD FILES
clear
mainDir = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\Releases\IVCAM2.0\Regression\';
mainDir = 'd:\Ohad\data\lidar\EXP\20170628\'
fns=dirRecursive(mainDir,'*.ivs');
%%
pout = [];
for i=1:length(fns)
    try
    pout = [pout Pipe.autopipe(fns{i})];
    disp(length(pout));
    catch 
    end
end


%%
N=size(pout(1).cma,1);
ti={pout.tiImg};
cma={pout.cma};
ti=cellfun(@(x) reshape(x,1,[]),ti,'uni',0);ti=[ti{:}];
tiMat = zeros(64,length(ti),'uint8');
tiMat(sub2ind([64 length(ti)],ti+1,1:length(ti)))=1;
cma=cellfun(@(x) reshape(x,N,[]),cma,'uni',0);cma=[cma{:}];
    k=vec(repmat(Utils.uint322bin(pout(1).regs.FRMW.txCode,pout(1).regs.GNRL.codeLength),1,pout(1).regs.GNRL.sampleRate)');
    k=buffer(k,1024);
data = [cma;tiMat];
%%
cmaDataFn = fullfile(mainDir,'cmaData.bin');
fid = fopen(cmaDataFn,'wb');
fwrite(fid,typecast(vec(data),'uint8'),'uint8');
fclose(fid);


copyfile(cmaDataFn,'\\perclnx53\ohaData\input\');
fprintf('Done\n');
