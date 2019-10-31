function FG_function(output_dir, name,dist_num)
ivs=Utils.FG_IVS('C:\Users\weisstom\Desktop\ivcam',1);

FlagsCodeStartMask = bitget(ivs.flags,2);
flag_indexes=[];
for index=1:length(FlagsCodeStartMask)
    if FlagsCodeStartMask(index)==1
        flag_indexes=[flag_indexes index];
    end
end

fast_size=512;
slow_size=8;
code_per_chunk=floor((flag_indexes(2)-flag_indexes(1))/slow_size)-1;
total_code_amount=code_per_chunk*length(flag_indexes);
fast=zeros(fast_size,total_code_amount,'logical');
slow=zeros(slow_size,total_code_amount,'uint16');

total_code=1;
for chunk=1:length(flag_indexes)
    chunk_start_slow=flag_indexes(chunk)+1;
    chunk_start_fast=(flag_indexes(chunk)-1)*64+2;
    for code=1:code_per_chunk
        fast(:,total_code)=ivs.fast(chunk_start_fast+fast_size*(code):chunk_start_fast+fast_size*(code+1)-1)';
        slow(:,total_code)=ivs.slow(chunk_start_slow+slow_size*(code):chunk_start_slow+slow_size*(code+1)-1)'; 
        total_code=total_code+1;
    end
end
imagesc(fast(:,1:1000));

% dist_num=450;
dist=dist_num*ones(1,total_code_amount);
save(fullfile(output_dir,strcat(name, num2str(dist_num),'.mat' )),'fast','slow','dist');
end