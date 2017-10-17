function lutOut = genJFILinnWeights()
n1=1/3;
n2=1/12;

a{1}=[
     0     0     0     0     0     0    n1    n1    n1     0     0     0     0     0
     0     0     1     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0
    ]';
 a{2}=[
     .7    .3    0     0     0
     0     0     0     0     0
     0     0     0     0     0
     ]';
 a{3}=[ 1     0     0]';%32 bit
 
 b{1}=[
     0
     0
     0
     0
     0
     ];
 b{2}=[
     0
     0
     0
     ];
 b{3}=[
     0
     ];

t1=@(X) cellfun(@(x) vec(x)',X,'uni',false);
t2 = @(X) [X{:}];
w =single([t2(t1(a)) t2(t1(b))]);
assert(min(abs(w(w~=0)))>Utils.fp20('to',uint32(hex2dec('0fff'))),'cannot implement denormalized vals in RTL');%smalled normalized FP value
assert(max(abs(Utils.fp20('to',Utils.fp20('from',w))-w))<1e-4,'accuracy degradation due to FP repesentation')
 
 
lut.data = Utils.fp20('from',w);
lut.block='JFIL';
lut.name='innWeights';
yl=[1 max(cellfun(@(x) size(x,1),a))];
xl=[1 max(cellfun(@(x) size(x,2),a))];
for i=1:length(a)
    subplot(2,length(a),i)
    imagesc(a{i});set(gca,{'xlim','ylim'},{xl,yl},'color','k');
    subplot(2,length(a),i+length(a))
    imagesc(b{i});set(gca,{'xlim','ylim'},{xl,yl},'color','k');
end    
    

 setLUTdata(lut);
end