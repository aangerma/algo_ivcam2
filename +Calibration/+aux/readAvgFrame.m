function avgD = readAvgFrame(hw,N)
for i = 1:N
   stream(i) = hw.getFrame(); 
end
collapseM = @(x) mean(reshape([stream.(x)],size(stream(1).(x),1),size(stream(1).(x),2),[]),3);
avgD.z=collapseM('z');
avgD.i=collapseM('i');
end