clear;
N = 26;
tic
codes = getAllValidCodes(N);
toc
score=zeros(size(codes,1),1);
c={};
for i=1:size(codes,1)
c{i}=Utils.correlator(codes(i,1:end),codes(i,:)*2-1)';
% c{i} = c{i}/sqrt(sum(c{i}.^2));
cs = sort(c{i});
score(i) = (cs(end)-cs(end-1));
end
[mx,mxInd]=max(score)
%%
brkrInd=arrayfun(@(i) find(sum(bsxfun(@xor,circshift(Codes.Barker13(1),[0 i]),codes).^2,2)==0)',1:N-1,'uni',false);
brkrInd=[brkrInd{:}];

brkrLike = find(sum(bsxfun(@minus,[c{:}],c{brkrInd}).^2,1)==0);

char(codes(brkrLike,:)+48)

plot([c{score==max(score)}]);
%%
codeInd = find(score==max(score));
MI = nan(length(codeInd));
for i=1:length(codeInd)
    codeA = codes(codeInd(i),:);
    for j=1:length(codeInd)
        codeB = codes(codeInd(j),:);
        cs = Utils.correlator((codeA+codeB)/2,codeB*2-1);
        cs = sort(cs);
        MI(i,j) = (cs(end)-cs(end-1));
       

    end
end
imagesc(MI);