clear all; close all; 
dist_num=1103;
load('X:\Users\hila\TxRxinvest\CodesStruct.mat');

%% !! remember before test WrConfigData C:\sources\ivcam2_project\Enable_Mems_ConfigData_Ver_02_11.txt // stop the mirror

outputFolder='X:\Users\hila\TxRxinvest\CodeTestData\Test4\codeData';
mkdirSafe(outputFolder); 
warning off

%%
inds=[6,17]; 
for(code_i=inds )%12:1:length(codes))
% code_i=7;
hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.runScript('X:\Users\tomer\FG\ldOn.txt');
pause(1);
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
out=strcat(outputFolder,'\FG_',num2str(dist_num),'\',codes(code_i).name);
mkdirSafe(out);
ivs=Utils.FG_IVS(out,1);
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
h=figure();
imagesc(fast(:,1:1000));


dist=dist_num*ones(1,total_code_amount);
dname=strcat(outputFolder,'\',num2str(dist_num));
mkdirSafe(dname);
save(strcat(outputFolder,'\',num2str(dist_num),'\',codes(code_i).name,'.mat' ),'fast','slow','dist');
saveas(h,strcat(outputFolder,'\',num2str(dist_num),'\',codes(code_i).name,'.png' ));

pause(2);
hw.cmd('rst');

pause(7);

end