clear
load TXexperiment
%%

  v=mmZ(200:5:400,200:5:400,:)/8;
mmZ(mmZ==0)=nan;
msk = std(mmZ(:,:,end-5:end),[],3)<1.5 ;
%  v=mm/8;
v=reshape(v,[],256);
%  v=v(msk,:);
vm=nanmedian(v);
vm=vm-vm(end);
vs=nanstd(v);
indx0=34

plot(iout(indx0:end),vm(indx0:end));
