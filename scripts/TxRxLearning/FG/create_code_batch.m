batch_size=10000;
%% build dataset from raw data
data_dir = 'C:\Users\weisstom\Desktop\ivcam\data32\raw';
files = dirFiles(data_dir,'*.mat');

temp=load(files{1});
slow_full=temp.slow;
fast_full=temp.fast;
dist_full=temp.dist;
for i=2:length(files)
    temp=load(files{i});
    slow_full=cat(2,slow_full,temp.slow);
    fast_full=cat(2,fast_full,temp.fast);
    dist_full=cat(2,dist_full,temp.dist);
    disp(i);    
end
perm=randperm(size(fast_full,2));
slow_full = slow_full(:,perm);
fast_full = fast_full(:,perm);
dist_full = dist_full(:,perm);

for i=1:size(dist_full,2)/batch_size
    slow = slow_full(:,(i-1)*batch_size+1:i*batch_size);
    fast = fast_full(:,(i-1)*batch_size+1:i*batch_size);
    dist = dist_full(:,(i-1)*batch_size+1:i*batch_size);
    save(strcat(data_dir,'\train\',string(i)),'fast','slow','dist');
    disp(i);
end

%% build data set and remove noise from laser off
% data_dir = 'C:\Users\weisstom\Desktop\ivcam\data16\raw\';
% slow_full=zeros(8,3513300*3,'uint16');
% fast_full=zeros(512,3513300*3,'logical');
% dist_full=zeros(1,3513300*3,'double');
% 
% i=1;
% for dist=500:50:4000
%     if dist~=2200
%         for filter=[0.25 0.5 1]
%             for frame=1:2
%                 temp=load(strcat(data_dir,string(dist),'\',string(filter),'\Frame000',string(frame),'.mat'));
%                 slow_full(:,(i-1)*25095+1:i*25095)=temp.slow;
%                 fast_full(:,(i-1)*25095+1:i*25095)=temp.fast;
%                 dist_full(:,(i-1)*25095+1:i*25095)=temp.dist;
%                 disp(strcat(data_dir,string(dist),'\',string(filter),'\Frame000',string(frame),'.mat'));
%                 i=i+1;
%             end
%         end
%     end
% end
% 
% %% remove noise of lisar off, remove if not nedded
% slow_filtered=zeros(8,1840300*3,'uint16');
% fast_filtered=zeros(512,1840300*3,'logical');
% dist_filtered=zeros(1,1840300*3,'double');
% for i=1:(1840300*3/55)     
%     slow_filtered(:,(i-1)*55+1:i*55)=slow_full(:,(i-1)*105+51:i*105);
%     fast_filtered(:,(i-1)*55+1:i*55)=fast_full(:,(i-1)*105+51:i*105);
%     dist_filtered(:,(i-1)*55+1:i*55)=dist_full(:,(i-1)*105+51:i*105);
%     disp(i);
% end
% 
% %%
% perm=randperm(size(fast_filtered,2));
% slow_full = slow_filtered(:,perm);
% fast_full = fast_filtered(:,perm);
% dist_full = dist_filtered(:,perm);
% 
% for i=1:size(dist_full,2)/batch_size
%     slow = slow_full(:,(i-1)*batch_size+1:i*batch_size);
%     fast = fast_full(:,(i-1)*batch_size+1:i*batch_size);
%     dist = dist_full(:,(i-1)*batch_size+1:i*batch_size);
%     save(strcat(data_dir,'\train\',string(i)),'fast','slow','dist');
%     disp(i);
% end

% 
% for d=600:50:3950
%     for filter=[0.25,0.5,1]
%         slow=zeros(8,50190,'uint16');
%         fast=zeros(512,50190,'logical');
%         dist=zeros(1,50190,'double');
%         slow_filtered=zeros(8,26290,'uint16');
%         fast_filtered=zeros(512,26290,'logical');
%         dist_filtered=zeros(1,26290,'double');
%         temp=load(strcat(data_dir,string(d),'\',string(filter),'\Frame0001.mat'));
%         slow(:,1:25095)=temp.slow;
%         fast(:,1:25095)=temp.fast;
%         dist(:,1:25095)=temp.dist;
%         temp=load(strcat(data_dir,string(d),'\',string(filter),'\Frame0002.mat'));
%         slow(:,25096:end)=temp.slow;
%         fast(:,25096:end)=temp.fast;
%         dist(:,25096:end)=temp.dist;
%         i=1;
%         for i=1:(26290/55)     
%             slow_filtered(:,(i-1)*55+1:i*55)=slow(:,(i-1)*105+51:i*105);
%             fast_filtered(:,(i-1)*55+1:i*55)=fast(:,(i-1)*105+51:i*105);
%             dist_filtered(:,(i-1)*55+1:i*55)=dist(:,(i-1)*105+51:i*105);
%         end
%         slow=slow_filtered;
%         fast=fast_filtered;
%         dist=dist_filtered;
%         save(strcat(data_dir,'\filtered\',string(filter),'\',string(d),'.mat'),'fast','slow','dist');
%         disp(strcat(data_dir,string(d)));
% 
%     end
% end
