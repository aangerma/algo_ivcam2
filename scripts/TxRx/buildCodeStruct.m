codes=struct;

names={'16_4','32_1','26_2','32_2','62_1','64_1','70_1','22_3'};
orig_code_length = [16,32,26,32,62,64,70,22];
new_code_length = [16*4,32,26*2,32*2,62,64,70,22*3];

for i=1:length(names)
    codes(i).name=names{i};
    [codes(i).code,codes(i).txCodeRegDec,codes(i).txCodeRegHex,codes(i).txCodeRegBin,codes(i).codeLength] = Codes.calculateCode(orig_code_length(i),new_code_length(i));    
    codes(i).tCode=repelem(codes(i).code,8);       
end

%% 'LFSR_31_2'
code=[1   1   0   0   0   0   0   0   0   0   1   1   0   0   1   1   0   0   1   1   1   1   1   1   0   0   1   1 ...
  1   1   0   0   0   0   0   0   1   1   1   1   1   1   1   1   1   1   0   0   0   0   1   1   1   1   0   0 ...
  1   1   0   0   0   0] ; 
c.name='LFSR_31_2'; 
codeL=31*2; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 
c=struct; 
%% 'LFSR_63'
 code=[0   0   0   0   0   1   0   0   0   0   1   1   0   0   0   1   0   1   0   0   1   1   1   1   0   1   0   0 ...
   0   1   1   1   0   0   1   0   0   1   0   1   1   0   1   1   1   0   1   1   0   0   1   1   0   1   0   1 ...
   0   1   1   1   1   1   1] ;
c.name='LFSR_63'; 
codeL=63; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 

c=struct; 

%% 'LFSR_127'
code=[0   0   0   0   1   1   1   0   1   1   1   1   0   0   1   0   1   1   0   0   1   0   0   1   0   0   0   0 ...
   0   0   1   0   0   0   1   0   0   1   1   0   0   0   1   0   1   1   1   0   1   0   1   1   0   1   1   0 ...
   0   0   0   0   1   1   0   0   1   1   0   1   0   1   0   0   1   1   1   0   0   1   1   1   1   0   1   1 ...
   0   1   0   0   0   0   1   0   1   0   1   0   1   1   1   1   1   0   1   0   0   1   0   1   0   0   0   1 ...
   1   0   1   1   1   0   0   0   1   1   1   1   1   1   1]; 

c.name='LFSR_127'; 
codeL=127; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 

c=struct; 
%% Rand
code=[  0   1   1   1   0   1   1   1   0   1   1   1   1   1   1   0   1   1   1   0   0   1   1   1   1   0   1   1 ...
   1   1   0   1   0   0   0   1   1   0   1   0   1   0   1   1   1   1   1   1   0   1   0   0   1   1   0  1 ...
   1   0   0   0   1   1   1   1]; 

c.name='Rand'; 
codeL=64; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 

c=struct; 
%% Rand_even
code=[   1   1   0   0   1   1   1   1   0   0   0   0   0   1   0   1   0   0   1   0   0   0   1   0   1   0   1   0 ...
   1   0   1   0   0   1   0   1   1   1   1   0   0   0   1   0   0   1   1   0   1   0   1   1   0   0   1   1 ...
   1   0   1   1   1   0   0   1]; 

c.name='Rand_even'; 
codeL=64; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 
