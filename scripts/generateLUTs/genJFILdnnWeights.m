function lutOut = genJFILdnnWeights(doUpdate)
%% Generate a LUT for gamma function.
if(~exist('doUpdate','var'))
    doUpdate=true;
end


nn_A{1}=[
     1     0     0     0     0     0     0     0     0     0     0    0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     
    ]';
 nn_A{2}=[
     
     1     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0
     ]';
 nn_A{3}=[
  
     1     0     0     0     0
     0     0     0     0     0
     0     0     0     0     0
     0     0     0     0     0
]';
 nn_A{4}=[1    0     0     0     ]';
 
 nn_B{1}=[
     0
     0
     0
     0
     0
     0
     0
     0
     0
     0
     ];
 nn_B{2}=[
     0
     0
     0
     0
     0
     ];
 nn_B{3}=[
     0
     0
     0
     0
     ];
 nn_B{4}=[0];
 

t1=@(X) cellfun(@(x) vec(x)',X,'uni',false);
t2 = @(X) [X{:}];
w =single([t2(t1(nn_A)) t2(t1(nn_B))]);
assert(min(abs(w(w~=0)))>Utils.fp20('to',uint32(hex2dec('0fff'))),'cannot implement denormalized vals in RTL');%smalled normalized FP value
assert(max(abs(Utils.fp20('to',Utils.fp20('from',w))-w))<1e-4,'accuracy degradation due to FP repesentation')
 
yl=[1 max(cellfun(@(x) size(x,1),nn_A))];
xl=[1 max(cellfun(@(x) size(x,2),nn_A))];
for i=1:length(nn_A)
    subplot(2,length(nn_A),i)
    imagesc(nn_A{i});set(gca,{'xlim','ylim'},{xl,yl},'color','k');
    subplot(2,length(nn_A),i+length(nn_A))
    imagesc(nn_B{i});set(gca,{'xlim','ylim'},{xl,yl},'color','k');
end

lut.data =  Utils.fp20('from',w);
lut.block = 'JFIL';
lut.name = 'dnnWeights';
if(doUpdate)
    setLUTdata(lut);
end


end