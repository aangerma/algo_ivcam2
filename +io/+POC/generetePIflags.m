function flags = generetePIflags(ivs,regs,txFreq)
N_FIRST_INVALID = 100;

n = size(ivs.xy,2);
ivs.xy(1,1:N_FIRST_INVALID)=-400;


[b,a]=butter(4,30e-6/(double(regs.GNRL.sampleRate)/64*0.5));
ys=filt_filt(b,a,double(ivs.xy(2,:)));


ld_on =abs(diff([0 ys]))>prctile(abs(diff(ys)),10);
ld_on(1:N_FIRST_INVALID+1)=false;
tx_code_start = [true false(1,n-1)];
scan_dir = [0 diff(ys)]>0;
txMode = iff(round(1/txFreq),0,1,nan,2);

flags = bitshift(uint8(ld_on        ),0) +...
        bitshift(uint8(tx_code_start),1) +...
        bitshift(uint8(scan_dir     ),2) +...
        bitshift(uint8(ones(1,n)*txMode       ),3);
    


if(0)
    %%
    clf
    c = double(ivs.xy(1,:)/4)+1j*double(ivs.xy(2,:));
    subplot(221);
    hold on;plot(c(ld_on),'.');plot(c(~ld_on),'.');plot(c(1),'go');hold off;
    rectangle('pos',[0 0 480 640]);
    axis equal
    title('ld\_on');
    
    c = double(ivs.xy(1,:)/4)+1j*double(ivs.xy(2,:));
    subplot(222);
    hold on;plot(c(scan_dir),'.');plot(c(~scan_dir),'.');hold off;
    rectangle('pos',[0 0 480 640]);
    axis equal
    title('scan\_dir');
    
end
end