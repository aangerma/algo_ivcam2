dist_num=450;
code_i=6;
outputFolder='X:\Users\hila\L520\TxRx\CodeTestData'; 
warning off
hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.runScript('C:\GIT\AlgoProjects\algo_ivcam2\scripts\TxRx\capture\ldOn.txt');
pause(1);

load('X:\Users\hila\L520\TxRx\CodesStruct.mat');
code=codes(code_i).code;

code2Use = uint32(codes(code_i).txCodeRegDec)';
hw.writeAddr(uint32(2231762944),code2Use(1));%EXTLauxPItxCode
hw.writeAddr(uint32(2231762948),code2Use(2));
hw.writeAddr(uint32(2231762960),code2Use(3));
hw.writeAddr(uint32(2231762964),code2Use(4));

hw.writeAddr(uint32(2684682680),uint32(length(code)));% EXTLauxPItxCodeLength
hw.cmd('mwd a00d01ec a00d01f0 00000111 // EXTLauxShadowUpdateFrame');
pause(0.1);
% hw.read('EXTLauxPItxCode')

ivs=Utils.FG_IVS(outputFolder,1);
hw.cmd('rst');

FlagsCodeStartMask = bitget(ivs.flags,2);
flag_indexes=[];
for index=1:length(FlagsCodeStartMask)
    if FlagsCodeStartMask(index)==1
        flag_indexes=[flag_indexes index];
    end
end

fast_size=8*length(code);
slow_size=ceil(length(code)/8);
code_per_chunk=floor((flag_indexes(2)-flag_indexes(1))/slow_size)-1;
total_code_amount=code_per_chunk*length(flag_indexes);
fast=zeros(fast_size,total_code_amount,'logical');
slow=zeros(slow_size,total_code_amount,'uint16');

total_code=1;
for chunk=1:length(flag_indexes)
    chunk_start_slow=flag_indexes(chunk)+1;
    chunk_start_fast=(flag_indexes(chunk)-1)*64+2;
    for i=1:code_per_chunk
        fast(:,total_code)=ivs.fast(chunk_start_fast+fast_size*(i):chunk_start_fast+fast_size*(i+1)-1)';
        slow(:,total_code)=ivs.slow(chunk_start_slow+slow_size*(i):chunk_start_slow+slow_size*(i+1)-1)'; 
        total_code=total_code+1;
    end
end
imagesc(fast(:,1:1000));


dist=dist_num*ones(1,total_code_amount);
dname=strcat(outputFolder,'\',num2str(dist_num));
mkdirSafe(dname);
save(strcat(outputFolder,'\',num2str(dist_num),'\',codes(code_i).name,'.mat' ),'fast','slow','dist');
