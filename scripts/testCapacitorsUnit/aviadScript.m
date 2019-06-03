hw = HWinterface();
hw.cmd('dirtybitbypass');
hw.getColorFrame(100);



hw.cmd('mwd 90050000 90050004 00000001'); % 200 Mhz

hw.cmd('MWD 90000034 90000038 00'); % Clock gating
frameRGB = hw.getFrame(10);
frameRGB = hw.getFrame(20);
figure,imagesc(frameRGB.z/4)




% hw.cmd('iww 20 100 1 0');
hw.cmd('MWD 90000034 90000038 ff');% No Clock gating
frameRGBNCG = hw.getFrame(10);
frameRGBNCG = hw.getFrame(20);
figure,imagesc(frameRGBNCG.z/4)



hw.cmd('mwd 90050000 90050004 00000002');

hw.cmd('MWD 90000034 90000038 00'); % Clock gating
frameRGB100 = hw.getFrame(10);
frameRGB100 = hw.getFrame(20);
figure,imagesc(frameRGB100.z/4)


% hw.cmd('iww 20 100 1 0');
hw.cmd('MWD 90000034 90000038 ff');% No Clock gating
frameRGBNCG100  = hw.getFrame(10);
frameRGBNCG100  = hw.getFrame(20);
figure,imagesc(frameRGBNCG100 .z/4)

z2mm = double(hw.z2mm);
diff = double(frameRGB.z)./z2mm - double(frameNoRGB.z)./z2mm;
figure();imagesc(diff,[-10 10])
figure();plot(mean(diff))

subsI = 165:195;
means = [mean(single(frameRGB.z(subsI,:)));
mean(single(frameRGB100.z(subsI,:)));
mean(single(frameRGBNCG.z(subsI,:)));
mean(single(frameRGBNCG100.z(subsI,:)))]/4;

% figure, plot(means')8
% 
% figure, plot(means(1,:)), title('RGB Clock Gating  200')
% figure, plot(means(2,:)), title('RGB Clock Gating  100')
% figure, plot(means(3,:)), title('RGB No Clock Gating 100')
% figure, plot(means(4,:)), title('RGB no Clock Gating 200')

figure,
for i = 1:4
   y = means(i,:);
   x = 1:640;
   p = polyfit(x,y,1);
   y1 = polyval(p,x);
%    tabplot(i);
   plot(y)
   hold on
end

grid on
legend({'RGB CG  200';'RGB CG  100';'RGB NCG 100';'RGB NCG 200'})
