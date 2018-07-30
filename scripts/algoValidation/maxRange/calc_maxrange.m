 basefldr='Z:\taviram\Demo6\Wall80_named';
 f=dirRecursive(basefldr,'*.bin');
 f=cellfun(@(x) fileparts(x),f,'uni',0);
 f=unique(f);
 rd=regexp(f,[strrep(basefldr,'\','\\') '\\(?<z>[\d\.]+)\\(?<n>\d)'],'names');
 rd=[rd{:}];
 
 tf=[1 .5 .316 .25 .1 .05];
 
 
 regdata={'440536C5'
 'B7021410' 
 '4381BE9A' 
 '38174C6C'
 '43FAA547' 
 '4388D407' 
 '378C5CB2' 
 'B3B65B46'};

 k=reshape([typecast(uint32(hex2dec(regdata)),'single');1],3,3)';

 rd_=arrayfun(@(x) struct('z',str2num(x.z),'zexp',str2num(x.z)*sqrt(1/tf(str2num(x.n)))),rd);
 [u,v]=ndgrid(1:480,1:640);

 %%
  r=sqrt(320.^2+240.^2)*0.1;
 msk=(u-240).^2+(v-320).^2<r.^2;
 M=10;
 msk = msk.*(abs(u-240.5)<239.5-M & abs(v-320.5)<319.5-M);
 msk=msk>0;

  %%
  mes=[];
 for i=1:length(f)
     if(rd_(i).z>2e3)
         continue;
     end
     im=cellfun(@(x) double(reshape(typecast(uint8(fileread(x)),'uint16'),640,480)')/8,dirFiles(f{i},'*_Depth_*.bin'),'uni',0);
     im=reshape([im{:}],480,640,[]);
     im(im==0)=nan;
     imM=nanmean(im,3);
     
     imS=nanstd(im,[],3);
     
     
     zgt=rd_(i).z*ones(size(imM));
     
     zaac=nanmedian(imM(msk)-zgt(msk));
     zstd=sqrt(nanmean(imS(msk).^2));
     fr = nnz((im.*double(msk)>0))./(nnz(msk)*size(im,3));
%      [~,rgt]=Pipe.z16toVerts(zgt,k,1);
%      [~,rmes]=Pipe.z16toVerts(imM,k,1);
     z_eval=rd_(i).zexp;
     
     mes(end+1,:)=[z_eval(1) zaac zstd fr];
     [z_eval(1) zaac zstd]
 end
 %%
 [~,o]=sort(mes(:,1));
 mes_=mes(o,:);
 plot(mes_(:,1),mes_(:,3));
 grid on
grid minor
title('10% ROI')
xlabel('distance[mm]');
ylabel('z-std error[mm]');
set(gca,'xlim',[0 5000]);
%%
 plot(mes_(:,1),mes_(:,2)./mes_(:,1)*100);
 grid on
grid minor
title('10% ROI')
xlabel('distance[mm]');
ylabel('z-accuracy error[%]');
set(gca,'xlim',[0 5000]);