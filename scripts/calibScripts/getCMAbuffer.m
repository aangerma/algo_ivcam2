hw=HWinterface;
N=1;
hw.write('DCORoutIRcma$',uint32(1));
hw.write('JFILbypass$',uint32(1));
n=hw.read('GNRLtmplLength');
downSamplingR = bitshift(1,hw.read('DCORdecRatio'));
% hw.read('GNRLsampleRate');
%%
cma=zeros(n,480,640);
for i=0:n-1
    v= typecast(uint8([floor(double(i)/84) mod(i,84) 0 0]),'uint32');
    hw.write('DCORoutIRcmaIndex',v);
    cmaimg=hw.getFrame(N).i;
    cma(i+1,:,:)=cmaimg;
    imagesc(cmaimg,[0 63]);
    drawnow
end
%%
cma_dec = reshape(cma, downSamplingR, double(n)/downSamplingR, size(cma,2), size(cma,3));
cma_dec = permute(sum(uint32(cma_dec),1, 'native'),[2 3 4 1]);

k=kron(Codes.propCode(64,1),ones(8,1));
k_dec=uint8(permute(sum(reshape(k,downSamplingR,[],size(k,2))),[2 3 1]))/downSamplingR;
k_dec=mean(buffer(k,10,2))';
c_dec=Utils.correlator(double(cma_dec),double(k_dec)*2-1);
c=Utils.correlator(cma,k*2-1);
c_dec_i=interp1(linspace(0,1,size(c_dec,1)),c_dec,linspace(0,1,size(c,1)),'previous');
Utils.displayVolumeSliceGUI([c c_dec_i],[0 640])