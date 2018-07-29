clear;
t=[];
T=[];
vZ=[];
vI=[];

hw=HWinterface;
hw.write('RASTbiltBypass',uint32(1));
hw.write('JFILbypass$',uint32(1));
hw.write('DIGGgammaScale','01000100');
hw.shadowUpdate();
sz=[480 640];
msk=imdilate(padarray(ones(2),sz/2-1,0,'both'),strel('disk',25,8))>0;
hw.cmd('algo_thermloop_en 10');
 hw.write('DCORspare_000',typecast(single(-0.5),'uint32'))
t0=tic;


while(true)
    d=hw.getFrame(30);
    vZ(end+1)=mean(d.z(msk))/8 *2; %rtd like
    vI(end+1)=mean(d.i(msk));
    T(end+1)=hw.getTemperature();
    t(end+1)=toc(t0);
    %%
    plotF = @(X) plot(t(2:end),X(2:end),t(4:end-2),conv(X(2:end),ones(1,5)/5,'valid'));
    
    clf;
    subplot(3,3,1:2); plotF(T);title('Temperature');axis tight;grid on;grid minor
    subplot(3,3,4:5); plotF(vZ);title('depth');axis tight;grid on;grid minor
    subplot(3,3,7:8); plotF(vI);title('IR');axis tight;grid on;grid minor
    if(length(T)>10)
    subplot(2,3,3);plot(T(2:end),vZ(2:end),'.');xlabel('T');ylabel('Z');grid on;grid minor;
    ab=(T(3:end)'.*[1 0]+[0 1])\vZ(3:end)';
    line(T([3 end]),T([3 end])*ab(1)+ab(2),'color','k','linewidth',2);
    text(min(T),median(vZ),sprintf('y=%5.2f x+ %5.2f',ab));
    subplot(2,3,6);plot(T(2:end),vI(2:end),'.');xlabel('T');ylabel('I');grid on;grid minor
        ab=(T(3:end)'.*[1 0]+[0 1])\vI(3:end)';
    line(T([3 end]),T([3 end])*ab(1)+ab(2),'color','k','linewidth',2)
    text(min(T),median(vI),sprintf('y=%5.2f x+ %5.2f',ab));
    drawnow;
    end
end