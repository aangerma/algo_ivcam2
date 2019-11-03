% 
% for dist=500:50:4000
%     data_dir = strcat('\\ger\ec\proj\ha\RSG\SA_3DCam\Algorithm\Share\CaptureLoopFG\output\',string(dist),'\1');
%     files = dirFiles(char(data_dir),'*.mat');
%     cpf=25095;
% 
%     slow=zeros(8,501900);
%     fast=zeros(512,501900);
%     for i=1:length(files)
%         temp=load(files{i});
%         slow(:,(i-1)*cpf+1:i*cpf)=temp.slow;
%         fast(:,(i-1)*cpf+1:i*cpf)=temp.fast;
%     end
%     % imshow(fast(:,1:1000))
%     save(strcat('C:\Users\weisstom\Desktop\ivcam\full_data\',string(dist),'.mat'),'fast','slow','dist')
% end

% %%flip bit ratio
% flip=zeros(3,71);
% i=1;
% for dist=500:50:4000
%     load(strcat('C:\Users\weisstom\Desktop\ivcam\full_data\',string(dist),'.mat'));
%     fast_mean=mean(fast,2);
%     code=fast_mean>0.5;
%     bit_flip = code~=fast;
%     bit_flip = mean(bit_flip,2);
% 
%     flip(1,i)=mean(bit_flip);
%     flip(2,i)=mean(bit_flip.*code);
%     flip(3,i)=mean(bit_flip.*(1-code));
%     i=i+1;
% end
% plot(500:50:4000,flip')
% legend('total','1','0')

%%plot dist stat
dist=3600;
filter=0.5;
% load(strcat('C:\Users\weisstom\Desktop\ivcam\full_data\',string(dist),'.mat'));
load(strcat('C:\Users\weisstom\Desktop\ivcam\data32\raw\filtered\',string(filter),'\',string(dist),'.mat'));
figure(3);imagesc(fast(:,1:1000));
fast_mean=mean(fast,2);
fast_std=std(fast,0,2);
code=fast_mean>0.5;
bit_flip = code~=fast;
bit_flip = mean(bit_flip,2);
figure(2);plot(code);
hold on
plot(fast_mean);
% plot(fast_std,'r');
%plot(bit_flip,'b');
hold off
legend('code','mean');