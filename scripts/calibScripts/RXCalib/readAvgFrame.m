function avgD = readAvgFrame(hw,K)
for i = 1:K
   stream(i) = hw.getFrame(); 
   im = double(uint16(stream(i).i)+bitshift(uint16(stream(i).c),8));
   im(im==0)=nan;
   stream(i).i = im;
   
   im = double(stream(i).z);
   im(im==0)=nan;
   stream(i).z = im; 
end
collapseM = @(x) mean(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),3,'omitnan');
avgD.z=collapseM('z');
avgD.i=collapseM('i');
end
