
% hw=HWinterface();
%%
t_hist=zeros(1,100);
while(true)
    
    d=hw.getFrame(60);
    t_hist = [t_hist(2:end) hw.getTemperature()];
    plot(t_hist);
    drawnow;
    if(std(t_hist)==1e-3)
        break;
    end
end
%%
msk=false(480,640);msk(300,300)=true;
[~,modRef] = hw.cmd('irb e2 0a 01');
[~,ibias] = hw.cmd('irb e2 06 01');
hw.cmd('iwb e2 0a 01 0b');%set mod ref value
hw.cmd('iwb e2 09 01 0b'); % max modulation

hw.cmd('iwb e2 03 01 13');% internal modulation (from register) ImodOperation
mmZ=zeros(480,640,256);
mmI=zeros(480,640,256);
for i=0:255
         
         cmd = sprintf('iwb e2 08 01 %02x',i);
         hw.cmd(cmd);
         d=hw.getFrame(60);
         mmZ(:,:,i+1)=d.z;
         mmI(:,:,i+1)=d.i;
      fprintf('%d %f\n',i,mmZ(300,300,i+1));
     
end
iout = (0:255)/255*(double(modRef)/63+1)*150+double(ibias)/255*60;
save TXexperiment 