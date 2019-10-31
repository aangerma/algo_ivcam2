%% add psnr to already created dataset

% [fw,p] = Pipe.loadFirmware();
% [regs,luts] = fw.get();

%% psnr calc as in pipe
% data_dir = 'C:\Users\weisstom\Desktop\ivcam\data32\train\';
% files = dirFiles(data_dir,'*.mat');
% 
% for i=1:length(files)
%     load(files{i});
%     disp(files{i});
%     iImgRAW = mean(slow,1);
%     dIR = max(0, int16(iImgRAW)-int16(0));
%     irIndex = map(regs.DCOR.irMap, min(63, bitshift(dIR, -int8(6)))+1); %
%     64 template
% 
%     ambIndex = uint8(ones(size(iImgRAW))*8); % choose constant (8) ambient to
%                                               all th dataset
% 
%     psnrIndex = bitor(bitshift(ambIndex, 4), irIndex);
%     psnr = map(regs.DCOR.psnr, uint16(psnrIndex)+1);
%     save(files{i},'fast','slow','dist','psnr');
% end


%% split dataset with psnt to folder for each psnr
data_dir = 'C:\Users\weisstom\Desktop\ivcam\data32\raw\with_psnr';
len=zeros(64,1);
for f=[0.25 0.5 1] % filter to include in the dataset
    for d=600:50:3950 % distance to include in the dataset
        temp=load(strcat(data_dir,'\',string(f),'\',string(d),'.mat'));
        for i=1:64
           len(i)=len(i)+length(temp.psnr(temp.psnr==(i-1))); 
        end
    end
end
fast_full=cell(64,1);
slow_full=cell(64,1);
dist_full=cell(64,1);
for i=1:64
    slow_full{i}=zeros(8,len(i),'uint16');
    fast_full{i}=zeros(512,len(i),'logical');
    dist_full{i}=zeros(1,len(i),'double');
end

index=ones(64,1,'uint32');
for f=[0.5 1]
    for d=600:50:3950
        temp=load(strcat(data_dir,'\',string(f),'\',string(d),'.mat'));
        for i=1:64
            len_i=length(temp.psnr(temp.psnr==(i-1)));
            if len_i~=0
                slow_full{i}(:,index(i):index(i)+len_i-1)=temp.slow(:,temp.psnr==(i-1));
                fast_full{i}(:,index(i):index(i)+len_i-1)=temp.fast(:,temp.psnr==(i-1));
                dist_full{i}(:,index(i):index(i)+len_i-1)=temp.dist(:,temp.psnr==(i-1));
                index(i)=index(i)+len_i; 
            end
        end
    end
end

batch_size=10000;
for i=1:64
    if len(i)~=0
        perm=randperm(size(fast_full{i},2));
        slow_temp = slow_full{i}(:,perm);
        fast_temp = fast_full{i}(:,perm);
        dist_temp = dist_full{i}(:,perm);

        for j=1:size(dist_temp,2)/batch_size
            slow = slow_temp(:,(j-1)*batch_size+1:j*batch_size);
            fast = fast_temp(:,(j-1)*batch_size+1:j*batch_size);
            dist = dist_temp(:,(j-1)*batch_size+1:j*batch_size);
            save(strcat('C:\Users\weisstom\Desktop\ivcam\data32\psnr_div0.5\',string(i),'\',string(j),'.mat'),'fast','slow','dist');
            disp(strcat('C:\Users\weisstom\Desktop\ivcam\data32\psnr_div0.5\',string(i),'\',string(j),'.mat'));
        end
    end
end
