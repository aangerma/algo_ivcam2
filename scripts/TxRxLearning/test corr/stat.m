dec=4;
invalid_threshold=15;
repeat=10000;

load('C:\sources\ivcam2_project\tCode.mat','tCode');
code64=tCode(1:8:end);

code62=Codes.propCode(62,1);
code32=Codes.propCode(32,1);
code32=repmat(code32,1,2)';
code32=code32(:);
code16=Codes.propCode(16,1);
code16=repmat(code16,1,4)';
code16=code16(:);

code=dec2bin(hex2dec('514d38913efc37a1'));
% code=dec2bin(hex2dec('3ad79ea600dc4d36'));
c=zeros(1,length(code));
for i=1:length(code)
    c(i)=str2num(code(i));
end

LFSR=[0 0 0 0 0 1 0 0 0 0 1 1 0 0 0 1 0 1 0 0 1 1 1 1 0 1 0 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 1 1 1 0 1 1 0 0 1 1 0 1 0 1 0 1 1 1 1 1 1];


s=zeros(5,51,repeat);
i=1;
for noise=0:0.01:0.5
%     for shrink=-10:10
        for j=1:repeat
            shift=randi([1 62*8-1]);
            shrink=randi([-10 10]);
            shrink_pos=randi([20 480]); 
%             si=uint8(shrink+11);
            s(1,i,j)=auto_corr(code64',noise,dec,0,shrink,shift,shrink_pos);
            s(2,i,j)=auto_corr(code62',noise,dec,0,shrink,shift,shrink_pos);
            s(3,i,j)=auto_corr(code32',noise,dec,0,shrink,shift,shrink_pos);
            s(4,i,j)=auto_corr(code16',noise,dec,0,shrink,shift,shrink_pos);
            s(5,i,j)=auto_corr(c,noise,dec,0,shrink,shift,shrink_pos);
            s(6,i,j)=auto_corr(LFSR,noise,dec,0,shrink,shift,shrink_pos);
        end
%     end
    i=i+1;
end
s1=s;

s=s1>30;
% s=squeeze(s);
s=mean(double(s),3);
plot(0:0.01:0.5,s')
legend('prop64','prop62','prop32','prop16','minimal','LFSR');
% axis([0.2 0.5 0 1]);