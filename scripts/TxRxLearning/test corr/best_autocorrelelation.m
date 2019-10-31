dec=4;
noise=0.4;
shrink_expand_noise=10;
shrink=randi([-shrink_expand_noise shrink_expand_noise]);
shift=randi([1 61*8]);
shrink_pos=randi([20 490]);

% load('C:\sources\ivcam2_project\tCode.mat','tCode');
% tCode=tCode(1:8:end);
tCode=Codes.propCode(62,1);
figure(1)
title('code62')
% autocorr(tCode,'NumLags',length(tCode)-1)

auto_corr(tCode',noise,dec,1,shrink,shift,shrink_pos);

code=dec2bin(hex2dec('514d38913efc37a1'));
% code=dec2bin(hex2dec('3ad79ea600dc4d36'));
c=zeros(1,length(code));
for i=1:length(code)
    c(i)=str2num(code(i));
end
figure(2)
title('optimal')
% autocorr(c512,'NumLags',length(c512)-1)

auto_corr(c,noise,dec,1,shrink,shift,shrink_pos);

lfsr=[0 0 0 0 0 1 0 0 0 0 1 1 0 0 0 1 0 1 0 0 1 1 1 1 0 1 0 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 1 1 1 0 1 1 0 0 1 1 0 1 0 1 0 1 1 1 1 1 1];
figure(3)
title('LFSR')
% autocorr(lfps512,'NumLags',length(lfps512)-1)
auto_corr(lfsr,noise,dec,1,shrink,shift,shrink_pos);
disp('shrink '+string(shrink)+' shift '+string(shift)+' pos '+string(shrink_pos))
