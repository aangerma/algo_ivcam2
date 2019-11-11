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


%% inverse 16x4
c.name='Reversed_16_4'; 
new_code_length=64; 
orig_code_length=16; 
orig_code = Codes.propCode(orig_code_length,1);
code =repelem(orig_code,new_code_length/orig_code_length)';
code=code+1; 
code(code==2)=0; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,new_code_length);
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c;

%% unbalanced32x2
code=[0   0   0   0   1   1   0   0   1   1   0   0   0   0   1   1   0   0   1   1   0   0   1   1   0   0   1   1 ...
1   1   0   0   0   0   1   1   0   0   0   0   1   1   0   0   1   1   0   0   1   1   0   0   0   0   1   1 ...
1   1   0   0   0   0   1   1] ; 

c.name='unbalanced_32_2'; 
codeL=64; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,codeL); 
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c; 

%% cat 16x2 32x1
c.name='cat_16_2_32_1'; 
new_code_length=64; 
orig_code = Codes.propCode(16,1);
code16_2 =repelem(orig_code,32/16)';
code32_1=  Codes.propCode(32,1)';
code=[code16_2,code32_1]; 
[c.txCodeRegDec,c.txCodeRegHex,c.txCodeRegBin,c.codeLength] = Codes.genCodeReg(code,new_code_length);
c.code=code'; 
c.tCode=repelem(c.code,8);       
codes(end+1)=c;
%% normelized code struct for length of ~127

normelizedCode=codes;

for r=1:length(codes)
if normelizedCode(r).codeLength==127
    continue ;
else 
    if normelizedCode(r).codeLength>50
        normelizedCode(r).tCode=[codes(r).tCode ; codes(r).tCode]  ;
    else %32
        normelizedCode(r).tCode=[codes(r).tCode ; codes(r).tCode ; codes(r).tCode ; codes(r).tCode]  ;
    end 
end 

 
end