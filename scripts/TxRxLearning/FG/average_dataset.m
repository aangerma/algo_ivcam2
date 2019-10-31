%% build new dataset from raw data each signal in the new dataset is average of few signals in the original dataset
data_dir = 'C:\Users\weisstom\Desktop\ivcam\data32\raw\with_psnr';
average=4;
for f=[1]
    for d=600:50:3950
        temp=load(strcat(data_dir,'\',string(f),'\',string(d),'.mat'));
        len=floor(size(temp.fast,2)/average);
        fast=reshape(temp.fast(:,1:len*average),512,average,[]);
        slow=reshape(temp.slow(:,1:len*average),8,average,[]);
        fast=squeeze(mean(fast,2));
        slow=squeeze(mean(slow,2));
        dist=temp.dist(1,1:len);
        save(strcat('C:\Users\weisstom\Desktop\ivcam\data32\average4\',string(f),'\',string(d),'.mat'),'fast','slow','dist');
        disp(strcat('C:\Users\weisstom\Desktop\ivcam\data32\average4\',string(f),'\',string(d),'.mat'));
    end
end