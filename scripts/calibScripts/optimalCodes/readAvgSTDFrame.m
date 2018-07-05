function [avgD,stdD] = readAvgSTDFrame(hw,K)
for i = 1:K
   stream(i) = hw.getFrame(); 
   im = double(stream(i).i);
   im(im==0)=nan;
   stream(i).i = im;
   
   im = double(stream(i).z);
   im(im==0)=nan;
   stream(i).z = im;
   
   im = double(stream(i).c);
   im(im==0)=nan;
   stream(i).c = im;
end
collapseMean = @(x) mean(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),3,'omitnan');
collapseSTD = @(x) std(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),[],3,'omitnan');
avgD.z=collapseMean('z');
avgD.i=collapseMean('i');
avgD.c=collapseMean('c');
stdD.z=collapseSTD('z');
stdD.i=collapseSTD('i');
stdD.c=collapseSTD('c');
end