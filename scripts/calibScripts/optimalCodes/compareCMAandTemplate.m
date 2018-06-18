load('template64.mat');
load('cma64.mat');
rec = cma64(:,240,320);
c = (cconv( rec,template,512));
[~,peakat] = max(c);
subplot(3,1,1);
stem(flipud(template))
subplot(3,1,2);
stem(circshift(rec,-peakat+1))
subplot(3,1,3);
stem(cconv( circshift(rec,-peakat+1),template,512))
%% Template 64 is exactly opposite to the cma. 