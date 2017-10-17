function ok=xRateCheck(x,y,regs)
%%
%hardware defenitions
ASIC_CLK_FREQ=0.25;%Ghz
N_HW_CYCLES_PER_PIXEL=5;
N_COLS_BUFFER=64;%4???
n=length(x);
%
    xlutIndx = bitshift(x-1,-int16(regs.CBUF.xBitShifts+2));%x-1 -->zero base
    xlutIndx = max(0,min(15,xlutIndx));
    
     xbufferSize = vec(regs.CBUF.xRelease(xlutIndx+1));


dt = 64/double(regs.GNRL.sampleRate);
maxx = max(0,Pipe.CBUF.maxrun(double(x)));
%the time (nsec) that take to release N_COLS_BUFFER
nsec_to_release_cols=N_COLS_BUFFER*double(regs.GNRL.imgVsize)*N_HW_CYCLES_PER_PIXEL/ASIC_CLK_FREQ;
%the data is sampled with dt nsec/samples
samples_to_release_cols=nsec_to_release_cols/dt;
n_cols_in_release_cycle=maxx-maxx(max(1,(1:n)-samples_to_release_cols));
xrate = n_cols_in_release_cycle(:)./double(N_COLS_BUFFER-xbufferSize(:));

okloc =x>=1 & x<=regs.GNRL.imgHsize*4 & y>=1 & y<=regs.GNRL.imgVsize;

badLocs=xrate>1 & okloc(:);
ok = all(~badLocs);
if(regs.MTLB.debug)
    %%
    figure(45345435)

    subplot(211)
    plot((1:n)*dt,xrate);
    xlabel('Time[nsec]');
    ylabel('$\frac{inputRate}{outputRate}$','interpreter','latex');
    line(get(gca,'xlim'),[1 1],'color','r','linestyle','--');
    subplot(212)
         plot(x,y,x(badLocs),y(badLocs),'r.');
         rectangle('pos',[0 0 regs.GNRL.imgHsize*4 regs.GNRL.imgVsize]);
         axis equal
end
end